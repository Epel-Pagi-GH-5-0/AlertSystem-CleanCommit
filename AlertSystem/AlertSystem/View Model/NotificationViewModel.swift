//
//  Notification.swift
//  AlertSystem
//
//  Created by Joshua Wenata Sunarto on 11/07/24.
//

import Foundation
import UserNotifications
import UIKit

class NotificationViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    @Published var notifications: [UNNotification] = []
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permissions denied.")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle notifications received while the app is in the foreground
        completionHandler([.alert, .sound, .badge])
        
        // Optionally, update your notifications list
        DispatchQueue.main.async {
            self.notifications.append(notification)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle user interaction with notifications (e.g., open specific screen)
        print("Received notification response: \(response)")
        
        completionHandler()
    }
}
