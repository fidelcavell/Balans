//
//  NotificationManager.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 22/07/26.
//

import Foundation
import Observation
import UserNotifications
import UIKit

import SwiftData

@Observable
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    // MARK: - Published State
    var isAuthorized: Bool = false
    
    var isNotificationsEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isNotificationsEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isNotificationsEnabled")
            if !newValue {
                cancelAllNotifications()
            }
        }
    }
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkNotificationPermission()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkNotificationPermission),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Functions
    @objc func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                let authorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
                self.isAuthorized = authorized
                
                // If system permission was revoked outside the app, cancel everything
                if !authorized {
                    self.cancelAllNotifications()
                }
            }
        }
    }
    
    func toggleNotifications(turnOn: Bool) {
        if turnOn {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                Task { @MainActor in
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        self.requestAuthorization()
                    case .denied:
                        self.openAppSettings()
                    case .authorized, .provisional, .ephemeral:
                        self.isNotificationsEnabled = true
                        self.isAuthorized = true
                        
                        if let context = DataProvider.shared.context as ModelContext? {
                            self.checkAndNotifyBudgetLimit(context: context)
                        }
                        
                    @unknown default:
                        break
                    }
                }
            }
        } else {
            self.isNotificationsEnabled = false
        }
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        guard isNotificationsEnabled && isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification: \(title) - \(body)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("All pending and delivered notifications have been removed!")
    }
    
    /// Recalculates current month's spending and triggers a notification if it is between 70% and 85% of limit.
    func checkAndNotifyBudgetLimit(context: ModelContext) {
        let prefDescriptor = FetchDescriptor<Preference>()
        guard let preference = try? context.fetch(prefDescriptor).first else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.month, .year], from: now)
        
        let transactionDescriptor = FetchDescriptor<Transaction>()
        guard let transactions = try? context.fetch(transactionDescriptor) else { return }
        
        let currentMonthSpending = transactions
            .filter { transaction in
                guard transaction.type == .outflow else { return false }
                let tComponents = calendar.dateComponents([.month, .year], from: transaction.occurredAt)
                return tComponents.month == currentComponents.month && tComponents.year == currentComponents.year
            }
            .reduce(0.0) { $0 + $1.amount }
        
        // Update preference currentSpending in DB
        preference.currentSpending = Int(currentMonthSpending)
        try? context.save()
        
        let limit = Double(preference.monthlySpendingLimit)
        guard limit > 0 else { return }
        
        let ratio = currentMonthSpending / limit
        
        if ratio >= 0.75 {
            let percentageUsed = Int(ratio * 100)
            
            // Check if budget warning is already pending to prevent duplicate spam
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let hasBudgetAlert = requests.contains { $0.content.title.contains("Budget Warning") }
                if !hasBudgetAlert {
                    Task { @MainActor in
                        self.scheduleNotification(
                            title: "Budget Warning ⚠️",
                            body: "You have used \(percentageUsed)% of your monthly spending limit (\(Int(currentMonthSpending).formatted(.currency(code: "IDR"))) of \(Int(limit).formatted(.currency(code: "IDR")))).",
                            timeInterval: 1
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, _ in
            Task { @MainActor in
                self.isAuthorized = success
                if success {
                    self.isNotificationsEnabled = true
                    
                    // Trigger check immediately when user enables notifications
                    if let context = DataProvider.shared.context as ModelContext? {
                        self.checkAndNotifyBudgetLimit(context: context)
                    }
                }
            }
        }
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

