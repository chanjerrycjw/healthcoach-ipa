import Foundation
import UserNotifications

enum Notifier {
    static func requestAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func reschedule(_ items: [ReminderItem]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for item in items where item.enabled {
            var comps = DateComponents()
            comps.hour = item.hour
            comps.minute = item.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
    }
}
