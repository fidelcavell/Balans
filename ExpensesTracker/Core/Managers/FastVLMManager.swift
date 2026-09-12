import CoreImage
import Foundation
import MLX
import MLXLMCommon
import MLXRandom
import MLXVLM
import SwiftUI
import Tokenizers

private struct FastVLMTokenizerLoader: TokenizerLoader {
    func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        let upstream = try await Tokenizers.AutoTokenizer.from(modelFolder: directory)
        return TokenizerBridge(upstream: upstream)
    }
}

private struct TokenizerBridge: MLXLMCommon.Tokenizer {
    let upstream: any Tokenizers.Tokenizer

    func encode(text: String, addSpecialTokens: Bool) -> [Int] {
        upstream.encode(text: text, addSpecialTokens: addSpecialTokens)
    }

    func decode(tokenIds: [Int], skipSpecialTokens: Bool) -> String {
        upstream.decode(tokens: tokenIds, skipSpecialTokens: skipSpecialTokens)
    }

    func decode(tokenIds: [Int]) -> String {
        upstream.decode(tokens: tokenIds, skipSpecialTokens: true)
    }

    func decode(tokens: [Int]) -> String {
        upstream.decode(tokens: tokens, skipSpecialTokens: true)
    }

    func convertTokenToId(_ token: String) -> Int? {
        upstream.convertTokenToId(token)
    }

    func convertIdToToken(_ id: Int) -> String? {
        upstream.convertIdToToken(id)
    }

    var bosToken: String? { upstream.bosToken }
    var eosToken: String? { upstream.eosToken }
    var unknownToken: String? { upstream.unknownToken }

    func applyChatTemplate(
        messages: [[String: any Sendable]],
        tools: [[String: any Sendable]]?,
        additionalContext: [String: any Sendable]?
    ) throws -> [Int] {
        do {
            return try upstream.applyChatTemplate(
                messages: messages, tools: tools, additionalContext: additionalContext)
        } catch Tokenizers.TokenizerError.missingChatTemplate {
            throw MLXLMCommon.TokenizerError.missingChatTemplate
        }
    }
}

@Observable
@MainActor
public class FastVLMManager {
    public static let shared = FastVLMManager()

    public enum EvaluationState: String, CaseIterable, Sendable {
        case idle = "Idle"
        case processingPrompt = "Processing Prompt"
        case generatingResponse = "Generating Response"
    }

    public var evaluationState: EvaluationState = .idle
    public var promptTime: String = ""
    public var generatedText: String = ""
    public var isModelLoaded: Bool = false
    public var isGenerating: Bool = false
    public var errorMessage: String?

    public var modelContainer: ModelContainer?

    public struct PromptPreset: Identifiable, Hashable, Sendable {
        public let id: String
        public let name: String
        public let prompt: String
        public let promptSuffix: String

        public init(id: String = UUID().uuidString, name: String, prompt: String, promptSuffix: String) {
            self.id = id
            self.name = name
            self.prompt = prompt
            self.promptSuffix = promptSuffix
        }
    }

    /// Prompt presets matching official FastVLM demo app style (Question + Suffix constraint)
    public static let defaultPresets: [PromptPreset] = [
        PromptPreset(
            id: "final-total",
            name: "Receipt Final Total",
            prompt: "What is the final total amount to pay printed on this receipt?",
            promptSuffix: "Do not calculate, add, or sum numbers. Output only the single printed final payment amount number."
        ),
        PromptPreset(
            id: "read-label",
            name: "Read Printed Total",
            prompt: "What number is written next to Total or Grand Total on this receipt?",
            promptSuffix: "Output only the single number without calculation."
        ),
        PromptPreset(
            id: "strict-json",
            name: "Strict JSON",
            prompt: "What is the final total amount to pay on this receipt? Do not sum numbers.",
            promptSuffix: "Output only a single JSON object: {\"amount\": <number>}"
        ),
        PromptPreset(
            id: "friend-split",
            name: "Friends Split & Adjust",
            prompt: "Identify the items, quantities, and prices on this receipt and adjust them according to friend split instructions.",
            promptSuffix: "Output strictly JSON: {\"items\": [{\"name\": \"...\", \"quantity\": 1, \"price\": 0}], \"subtotal\": 0, \"tax\": 0, \"serviceCharge\": 0, \"discount\": 0, \"total\": 0, \"note\": \"...\"}"
        )
    ]

    /// Builds a prompt tailored for adjusting items bought together with friends using a voice transcription.
    public static func buildSplitPrompt(voiceInstruction: String) -> (prompt: String, promptSuffix: String) {
        let trimmed = voiceInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        let promptText: String
        if trimmed.isEmpty {
            promptText = "Identify and list all items with their quantities and prices from this receipt."
        } else {
            promptText = "From this receipt, adjust items, quantities, and prices according to the user instructions: \"\(trimmed)\"."
        }

        let suffixText = "Output strictly valid JSON: {\"items\": [{\"name\": \"item name\", \"quantity\": 1, \"price\": 10000}], \"subtotal\": 10000, \"tax\": 0, \"serviceCharge\": 0, \"discount\": 0, \"total\": 10000, \"note\": \"short summary\"}"

        return (promptText, suffixText)
    }

    public static var defaultPrompt: String {
        defaultPresets[0].prompt
    }

    public static var defaultPromptSuffix: String {
        defaultPresets[0].promptSuffix
    }

    /// Combined strict default receipt prompt for compatibility
    public static var strictReceiptAmountPrompt: String {
        "\(defaultPrompt) \(defaultPromptSuffix)"
    }

    /// Generation parameters matching official demo
    public let generateParameters = GenerateParameters(temperature: 0.0)
    public let maxTokens: Int = 240
    public let displayEveryNTokens: Int = 4

    private var currentTask: Task<Void, Never>?

    private init() {}

    public func loadModel() async throws {
        guard !isModelLoaded else { return }

        // Limit the buffer cache like official demo to prevent OOM
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

        let factory = VLMModelFactory.shared
        await FastVLM.register(modelFactory: factory)

        let config = FastVLM.modelConfiguration
        guard case .directory(let dir) = config.id else {
            throw NSError(
                domain: "FastVLM",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Model directory not found in app bundle"]
            )
        }

        self.modelContainer = try await factory.loadContainer(
            from: dir,
            using: FastVLMTokenizerLoader()
        )
        self.isModelLoaded = true
    }

    public func generate(prompt: String, image: UIImage) async throws -> String {
        guard let container = modelContainer else {
            throw NSError(
                domain: "FastVLM",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "FastVLM model is not loaded yet"]
            )
        }

        // Cancel previous task if running
        cancel()

        guard let ciImage = Self.makeOrientedCIImage(from: image) else {
            throw NSError(
                domain: "FastVLM",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid image format"]
            )
        }

        isGenerating = true
        generatedText = ""
        promptTime = ""
        errorMessage = nil
        evaluationState = .processingPrompt

        let userInput = UserInput(prompt: prompt, images: [.ciImage(ciImage)])

        let task = Task { [weak self] () throws -> String in
            guard let self else { return "" }
            do {
                // Seed random generator like official demo
                MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

                if Task.isCancelled {
                    await MainActor.run {
                        self.evaluationState = .idle
                        self.isGenerating = false
                    }
                    return ""
                }

                let outputText = try await container.perform { [weak self] context in
                    guard let self else {
                        return ""
                    }

                    await MainActor.run {
                        self.evaluationState = .processingPrompt
                    }

                    let llmStart = Date()
                    let input = try await context.processor.prepare(input: userInput)

                    var seenFirstToken = false

                    // Generate output with token callback matching official demo
                    let result: GenerateResult = try MLXLMCommon.generate(
                        input: input,
                        parameters: self.generateParameters,
                        context: context
                    ) { (tokens: [Int]) -> GenerateDisposition in
                        if Task.isCancelled {
                            return .stop
                        }

                        if !seenFirstToken {
                            seenFirstToken = true
                            let llmDuration = Date().timeIntervalSince(llmStart)
                            let text = context.tokenizer.decode(tokenIds: tokens)
                            Task { @MainActor in
                                self.evaluationState = .generatingResponse
                                self.generatedText = text
                                self.promptTime = "\(Int(llmDuration * 1000)) ms"
                            }
                        }

                        if tokens.count % self.displayEveryNTokens == 0 {
                            let text = context.tokenizer.decode(tokenIds: tokens)
                            Task { @MainActor in
                                self.generatedText = text
                            }
                        }

                        if tokens.count >= self.maxTokens {
                            return .stop
                        } else {
                            return .more
                        }
                    }

                    return result.output
                }

                if !Task.isCancelled {
                    await MainActor.run {
                        self.generatedText = outputText
                        self.evaluationState = .idle
                        self.isGenerating = false
                    }
                }
                return outputText
            } catch {
                await MainActor.run {
                    self.evaluationState = .idle
                    self.isGenerating = false
                    self.errorMessage = error.localizedDescription
                }
                throw error
            }
        }

        self.currentTask = Task {
            _ = try? await task.value
        }

        return try await task.value
    }

    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isGenerating = false
        if evaluationState != .idle {
            evaluationState = .idle
        }
    }

    // MARK: - Image Utilities

    public static func makeOrientedCIImage(from image: UIImage) -> CIImage? {
        if let ci = image.ciImage {
            return ci
        }
        guard let cg = image.cgImage else {
            return CIImage(image: image)
        }
        let ci = CIImage(cgImage: cg)
        let orientation: CGImagePropertyOrientation
        switch image.imageOrientation {
        case .up: orientation = .up
        case .down: orientation = .down
        case .left: orientation = .left
        case .right: orientation = .right
        case .upMirrored: orientation = .upMirrored
        case .downMirrored: orientation = .downMirrored
        case .leftMirrored: orientation = .leftMirrored
        case .rightMirrored: orientation = .rightMirrored
        @unknown default: orientation = .up
        }
        return ci.oriented(orientation)
    }

    // MARK: - Single Customer Payment Amount Extraction

    /// Extracts ONLY the single customer payment amount.
    /// Handles plain numbers, currency amounts, labeled amounts (Total / Grand Total / Total Bayar),
    /// equations (extracting the final result), and JSON objects.
    /// Strictly guarantees it NEVER sums detected numbers.
    public func extractAmount(from input: String? = nil) -> Double? {
        let text = (input ?? generatedText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // 1. Direct JSON parse
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let amt = parseAmountFromDict(json) {
                return amt
            }
        }

        // 2. Extract JSON if enclosed in markdown code fences or surrounded by other text
        if let regex = try? NSRegularExpression(pattern: #"\{[^{}]*"(?:amount|total|total_bayar|grand_total)"\s*:\s*([^,}\s]+)[^{}]*\}"#, options: .caseInsensitive) {
            let nsText = text as NSString
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) {
                let matchedString = nsText.substring(with: match.range)
                if let data = matchedString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let amt = parseAmountFromDict(json) {
                    return amt
                }
            }
        }

        // 3. Look for explicit total labels: "Grand Total: 45000", "Total Bayar: Rp 45.000", "Total: 45000", "Amount Due: 45000", "= 45000"
        let totalPatterns = [
            #"(?:grand\s*total|total\s*bayar|total\s*pembayaran|total\s*belanja|amount\s*due|balance\s*due|total)[\s:=]+(?:Rp\.?|IDR|\$)?\s*([0-9.,]+)"#,
            #"=\s*(?:Rp\.?|IDR|\$)?\s*([0-9.,]+)"#
        ]
        for pattern in totalPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsText = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
                if let lastMatch = matches.last, lastMatch.numberOfRanges > 1 {
                    let numStr = nsText.substring(with: lastMatch.range(at: 1))
                    if let val = sanitizeNumericString(numStr), val > 0 {
                        return val
                    }
                }
            }
        }

        // 4. Regex search for "amount": <number>
        if let regex = try? NSRegularExpression(pattern: #""(?:amount|total)"\s*:\s*"?([0-9.,]+)"?"#, options: .caseInsensitive) {
            let nsText = text as NSString
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)),
               match.numberOfRanges > 1 {
                let numStr = nsText.substring(with: match.range(at: 1))
                if let val = sanitizeNumericString(numStr), val > 0 {
                    return val
                }
            }
        }

        // 5. If the entire string is just a number/currency (e.g. "45000", "Rp 45.000", "$45.00", "45,000")
        if let directVal = sanitizeNumericString(text), directVal > 0 {
            return directVal
        }

        // 6. Extract candidate numbers from text (e.g. "The total amount to pay is 45000")
        // NEVER sum candidate numbers - take the last candidate which is typically the grand total
        let numberRegex = try? NSRegularExpression(pattern: #"(?:Rp\.?|IDR|\$)?\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?|[0-9]+)"#, options: .caseInsensitive)
        if let numberRegex {
            let nsText = text as NSString
            let matches = numberRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            let candidates = matches.compactMap { match -> Double? in
                guard match.numberOfRanges > 1 else { return nil }
                let str = nsText.substring(with: match.range(at: 1))
                return sanitizeNumericString(str)
            }.filter { $0 > 0 }

            if let lastCandidate = candidates.last {
                return lastCandidate
            }
        }

        return nil
    }

    private func parseAmountFromDict(_ dict: [String: Any]) -> Double? {
        if let d = dict["amount"] as? Double { return d }
        if let i = dict["amount"] as? Int { return Double(i) }
        if let s = dict["amount"] as? String { return sanitizeNumericString(s) }
        if let d = dict["total"] as? Double { return d }
        if let i = dict["total"] as? Int { return Double(i) }
        if let s = dict["total"] as? String { return sanitizeNumericString(s) }
        return nil
    }

    private func sanitizeNumericString(_ raw: String) -> Double? {
        var str = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        str = str.replacingOccurrences(of: "Rp", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "IDR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle Indonesian zero decimals e.g. ",00" or ".00"
        if str.hasSuffix(",00") || str.hasSuffix(".00") {
            str = String(str.dropLast(3))
        }

        // If string contains both . and , (e.g. "45.000,00" or "45,000.00")
        if str.contains(".") && str.contains(",") {
            let lastDot = str.lastIndex(of: ".")!
            let lastComma = str.lastIndex(of: ",")!
            if lastComma > lastDot {
                // "45.000,00" -> dot is thousand separator, comma is decimal
                str = str.replacingOccurrences(of: ".", with: "")
                str = str.replacingOccurrences(of: ",", with: ".")
            } else {
                // "45,000.00" -> comma is thousand separator, dot is decimal
                str = str.replacingOccurrences(of: ",", with: "")
            }
            return Double(str)
        }

        // If string contains dot
        if str.contains(".") {
            let parts = str.split(separator: ".")
            if parts.count > 2 {
                // Multiple dots e.g. 1.000.000 -> thousands separators
                str = str.replacingOccurrences(of: ".", with: "")
                return Double(str)
            } else if let last = parts.last, last.count == 3 {
                // Exactly 3 digits after dot -> thousands separator (e.g. 45.000)
                str = str.replacingOccurrences(of: ".", with: "")
                return Double(str)
            }
        }

        // If string contains comma
        if str.contains(",") {
            let parts = str.split(separator: ",")
            if parts.count > 2 {
                // Multiple commas e.g. 1,000,000 -> thousands separators
                str = str.replacingOccurrences(of: ",", with: "")
                return Double(str)
            } else if let last = parts.last, last.count == 3 {
                // Exactly 3 digits after comma -> thousands separator (e.g. 45,000)
                str = str.replacingOccurrences(of: ",", with: "")
                return Double(str)
            } else if let last = parts.last, last.count <= 2 {
                // Comma decimal (e.g. 45,50)
                str = str.replacingOccurrences(of: ",", with: ".")
                return Double(str)
            }
        }

        return Double(str)
    }

    // MARK: - Receipt Detail & Items Extraction for Friends Split

    /// Extracts itemized breakdown from FastVLM output.
    /// Parses JSON objects with `items` array, or falls back to line-item heuristics.
    public func extractReceiptDetail(from input: String? = nil) -> ExtractedReceiptDetail? {
        let text = (input ?? generatedText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // 1. Try decoding JSON directly from text or extracted JSON block
        if let jsonString = extractJSONSubstring(from: text),
           let data = jsonString.data(using: .utf8) {
            // Direct Decodable parse
            if let detail = try? JSONDecoder().decode(ExtractedReceiptDetail.self, from: data), !detail.items.isEmpty {
                return detail
            }

            // Dict parse with flexible keys
            if let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                if let detail = parseReceiptDetailFromDict(dict) {
                    return detail
                }
            }
        }

        // 2. Line-item regex heuristic extraction if FastVLM outputted bullet points or a list
        let fallbackItems = parseLineItemsFromText(text)
        if !fallbackItems.isEmpty {
            let total = extractAmount(from: text) ?? fallbackItems.reduce(0) { $0 + $1.totalPrice }
            return ExtractedReceiptDetail(
                items: fallbackItems,
                subtotal: fallbackItems.reduce(0) { $0 + $1.totalPrice },
                tax: 0,
                serviceCharge: 0,
                discount: 0,
                grandTotal: total
            )
        }

        return nil
    }

    private func extractJSONSubstring(from text: String) -> String? {
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start <= end {
            return String(text[start...end])
        }
        return nil
    }

    private func parseReceiptDetailFromDict(_ dict: [String: Any]) -> ExtractedReceiptDetail? {
        guard let itemsRaw = dict["items"] as? [[String: Any]], !itemsRaw.isEmpty else {
            return nil
        }

        let items: [ExtractedReceiptItem] = itemsRaw.compactMap { itemDict in
            guard let name = itemDict["name"] as? String, !name.isEmpty else { return nil }
            let price: Double
            if let p = itemDict["price"] as? Double { price = p }
            else if let p = itemDict["price"] as? Int { price = Double(p) }
            else if let s = itemDict["price"] as? String, let p = sanitizeNumericString(s) { price = p }
            else { price = 0 }

            let qty: Int
            if let q = itemDict["quantity"] as? Int { qty = q }
            else if let q = itemDict["quantity"] as? Double { qty = Int(q) }
            else if let s = itemDict["quantity"] as? String, let q = Int(s) { qty = q }
            else { qty = 1 }

            return ExtractedReceiptItem(name: name, price: price, quantity: qty)
        }

        guard !items.isEmpty else { return nil }

        let subtotal = (dict["subtotal"] as? Double) ?? (dict["subtotal"] as? Int).map(Double.init) ?? items.reduce(0) { $0 + $1.totalPrice }
        let tax = (dict["tax"] as? Double) ?? (dict["tax"] as? Int).map(Double.init) ?? 0
        let service = (dict["serviceCharge"] as? Double) ?? (dict["service_charge"] as? Double) ?? 0
        let discount = (dict["discount"] as? Double) ?? (dict["discount"] as? Int).map(Double.init) ?? 0
        let grandTotal = (dict["total"] as? Double)
            ?? (dict["grandTotal"] as? Double)
            ?? (dict["amount"] as? Double)
            ?? (subtotal + tax + service - discount)

        return ExtractedReceiptDetail(
            items: items,
            subtotal: subtotal,
            tax: tax,
            serviceCharge: service,
            discount: discount,
            grandTotal: grandTotal
        )
    }

    private func parseLineItemsFromText(_ text: String) -> [ExtractedReceiptItem] {
        var items: [ExtractedReceiptItem] = []
        let lines = text.components(separatedBy: .newlines)
        let itemPattern = #"(?:^|\s*[-*•]|\d+\.)\s*(?:(\d+)\s*[xX]\s+)?([A-Za-z0-9\s]+?)[\s:=-]+(?:Rp\.?|IDR|\$)?\s*([0-9.,]+)"#

        guard let regex = try? NSRegularExpression(pattern: itemPattern, options: .caseInsensitive) else {
            return []
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let nsLine = trimmed as NSString
            if let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: nsLine.length)) {
                var qty = 1
                if match.numberOfRanges > 1 && match.range(at: 1).location != NSNotFound {
                    let qtyStr = nsLine.substring(with: match.range(at: 1))
                    qty = Int(qtyStr) ?? 1
                }

                var name = ""
                if match.numberOfRanges > 2 && match.range(at: 2).location != NSNotFound {
                    name = nsLine.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                }

                var price: Double = 0
                if match.numberOfRanges > 3 && match.range(at: 3).location != NSNotFound {
                    let priceStr = nsLine.substring(with: match.range(at: 3))
                    price = sanitizeNumericString(priceStr) ?? 0
                }

                let lowerName = name.lowercased()
                if lowerName.contains("total") || lowerName.contains("subtotal") || lowerName.contains("tax") || lowerName.contains("pajak") || lowerName.contains("cash") || lowerName.contains("change") || lowerName.contains("kembali") {
                    continue
                }

                if !name.isEmpty && price > 0 {
                    items.append(ExtractedReceiptItem(name: name, price: price, quantity: qty))
                }
            }
        }
        return items
    }
}
