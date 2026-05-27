import Foundation
import UserNotifications
import SwiftUI
import UIKit

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    // HabitFlow-compatible toggle
    @Published var isEnabled: Bool {
        didSet {
            syncHabitToggle(fromIsEnabled: true, newValue: isEnabled)
        }
    }

    // Your app-compatible toggle
    @Published var habitRemindersEnabled: Bool {
        didSet {
            syncHabitToggle(fromIsEnabled: false, newValue: habitRemindersEnabled)
        }
    }

    @Published var reminderTime: Date {
        didSet {
            saveReminderTime()
            if isEnabled && isAuthorized {
                scheduleReminder()
            }
        }
    }

    private let notificationCenter = UNUserNotificationCenter.current()
    private let habitReminderIdentifier = "consciousconnection.habits.daily.reminder"
    private var isSyncingToggle = false

    private init() {
        let storedEnabled =
            UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ??
            UserDefaults.standard.object(forKey: "habitNotificationsEnabled") as? Bool ??
            false

        self.isEnabled = storedEnabled
        self.habitRemindersEnabled = storedEnabled

        if let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            self.reminderTime = savedTime
        } else if let savedTime = UserDefaults.standard.object(forKey: "habitReminderTime") as? Date {
            self.reminderTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            self.reminderTime = Calendar.current.date(from: components) ?? Date()
        }

        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // HabitFlow-compatible
    func requestAuthorization() {
        Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                isAuthorized = granted

                if granted && isEnabled {
                    scheduleReminder()
                }
            } catch {
                isAuthorized = false
            }
        }
    }

    // Your previous entry point
    func requestPermissionAndScheduleTaskReminders() {
        Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                isAuthorized = granted

                guard granted else {
                    print("Notification permission not granted")
                    return
                }

                scheduleTaskReminders()

                if isEnabled {
                    scheduleReminder()
                }
            } catch {
                print("Notification permission error:", error)
                isAuthorized = false
            }
        }
    }

    // MARK: - Task reminders

    func scheduleTaskReminders() {
        let ids = taskReminderIDs()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)

        scheduleMainTaskReminders()
        scheduleGratitudeTouchstoneReminders()
    }

    private func scheduleMainTaskReminders() {
        let weekdays: [Int] = [1, 3, 4, 5, 7]
        let times: [(hour: Int, minute: Int)] = [
            (8, 0), (10, 0), (14, 0), (20, 0), (21, 0)
        ]

        for weekday in weekdays {
            for time in times {
                let content = UNMutableNotificationContent()
                content.title = "ConsciousConnection"
                content.body = bodyText(forHour: time.hour)
                content.sound = .default

                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = time.hour
                dateComponents.minute = time.minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "taskReminder_\(weekday)_\(time.hour)_\(time.minute)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                notificationCenter.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification \(identifier):", error)
                    }
                }
            }
        }
    }

    private func scheduleGratitudeTouchstoneReminders() {
        let regularDays: [Int] = [1, 3, 4, 5, 7]
        let regularTimes: [(hour: Int, minute: Int)] = [(11, 0), (15, 0), (19, 0)]

        for weekday in regularDays {
            for time in regularTimes {
                addGratitudeTouchstoneReminder(weekday: weekday, hour: time.hour, minute: time.minute)
            }
        }

        let workdays: [Int] = [2, 6]
        for weekday in workdays {
            addGratitudeTouchstoneReminder(weekday: weekday, hour: 19, minute: 0)
        }
    }

    private func addGratitudeTouchstoneReminder(weekday: Int, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "ConsciousConnection"
        content.body = "Gratitude touchstone, Tess :)"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "touchstoneReminder_\(weekday)_\(hour)_\(minute)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification \(identifier):", error)
            }
        }
    }

    // MARK: - Habit reminders

    // HabitFlow-compatible
    func scheduleReminder() {
        cancelHabitReminder()

        guard isEnabled && isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to check your habits!"
        content.body = "Open Conscious Connection and track today’s habits."
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: habitReminderIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling habit reminder:", error)
            }
        }
    }

    func requestAuthorizationForHabits() {
        requestAuthorization()
    }

    func scheduleHabitReminder() {
        scheduleReminder()
    }

    func cancelHabitReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [habitReminderIdentifier])
        notificationCenter.setBadgeCount(0)
    }

    // HabitFlow-compatible
    func cancelAllNotifications() {
        cancelHabitReminder()
    }

    // MARK: - Settings

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Helpers

    private func syncHabitToggle(fromIsEnabled: Bool, newValue: Bool) {
        guard !isSyncingToggle else { return }
        isSyncingToggle = true

        if fromIsEnabled {
            habitRemindersEnabled = newValue
        } else {
            isEnabled = newValue
        }

        UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
        UserDefaults.standard.set(newValue, forKey: "habitNotificationsEnabled")

        if newValue {
            requestAuthorization()
        } else {
            cancelHabitReminder()
        }

        isSyncingToggle = false
    }

    private func saveReminderTime() {
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
        UserDefaults.standard.set(reminderTime, forKey: "habitReminderTime")
    }

    private func bodyText(forHour hour: Int) -> String {
        switch hour {
        case 8:
            return "Open your App, Tess :)"
        case 10, 14, 20:
            return "Check your tasks, Tess :)"
        case 21:
            return "Bedtime Wind Down :)"
        default:
            return "Check your tasks, Tess :)"
        }
    }

    private func taskReminderIDs() -> [String] {
        var ids: [String] = []

        let mainWeekdays: [Int] = [1, 3, 4, 5, 7]
        let mainTimes: [(hour: Int, minute: Int)] = [
            (8, 0), (10, 0), (14, 0), (20, 0), (21, 0)
        ]

        for weekday in mainWeekdays {
            for time in mainTimes {
                ids.append("taskReminder_\(weekday)_\(time.hour)_\(time.minute)")
            }
        }

        let touchstoneRegularDays: [Int] = [1, 3, 4, 5, 7]
        let touchstoneRegularTimes: [(hour: Int, minute: Int)] = [
            (11, 0), (15, 0), (19, 0)
        ]

        for weekday in touchstoneRegularDays {
            for time in touchstoneRegularTimes {
                ids.append("touchstoneReminder_\(weekday)_\(time.hour)_\(time.minute)")
            }
        }

        let touchstoneWorkdays: [Int] = [2, 6]
        for weekday in touchstoneWorkdays {
            ids.append("touchstoneReminder_\(weekday)_19_0")
        }

        return ids
    }
}
