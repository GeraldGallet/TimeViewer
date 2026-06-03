//
//  NotificationManager.swift
//  TimeViewer
//
//  Thin wrapper over UserNotifications for timer-completion alerts. Requests
//  authorization once at launch and posts a local notification when a timer ends.
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    /// Call once at launch. Sets the delegate and prompts for permission.
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in
            // If denied, notifications simply won't appear — nothing else to do.
        }
    }

    /// Post an immediate notification that a timer has finished.
    func notifyTimerFinished(name: String) {
        let content = UNMutableNotificationContent()
        content.title = "Timer finished"
        content.body = name
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // nil delivers immediately
        )
        UNUserNotificationCenter.current().add(request)
    }

    // Show the banner even when Time Viewer is the active app.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
