import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    var authorizationStatus: UNAuthorizationStatus {
        get async { await center.notificationSettings().authorizationStatus }
    }

    // MARK: - Review Reminder
    // Fires N days after a game is marked completed, if no review has been left

    func scheduleReviewReminder(for game: Game, delayDays: Int = 3) {
        guard game.status == .played,
              (game.review == nil || game.review!.trimmingCharacters(in: .whitespaces).isEmpty)
        else { return }

        let content = UNMutableNotificationContent()
        content.title = "How was \(game.title)?"
        content.body = "You finished it \(delayDays == 1 ? "yesterday" : "\(delayDays) days ago"). Leave a quick review while it's fresh."
        content.sound = .default
        content.userInfo = ["gameId": game.id, "type": "review_reminder"]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(delayDays * 86_400),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "review.\(game.id)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelReviewReminder(for gameId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["review.\(gameId)"])
    }

    // MARK: - Release Reminder
    // Fires on a wishlist game's release date at 9 AM

    func scheduleReleaseReminder(for game: Game, on releaseDate: Date) {
        guard releaseDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(game.title) drops today!"
        content.body = "Your wishlist game is now available. Time to play."
        content.sound = .default
        content.userInfo = ["gameId": game.id, "type": "release_reminder"]

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: releaseDate)
        comps.hour = 9
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "release.\(game.id)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelReleaseReminder(for gameId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["release.\(gameId)"])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
