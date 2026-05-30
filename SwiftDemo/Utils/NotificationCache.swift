import Foundation

/// In-memory notification cache with 5-minute TTL.
/// Shared between the nav bar badge and the notifications list VC.
final class NotificationCache {

    static let shared = NotificationCache()
    private init() {}

    private let ttl: TimeInterval = 5 * 60   // 5 minutes

    private var items: [NotificationItem] = []
    private var lastFetchedAt: Date?

    // MARK: - Public Properties

    var isValid: Bool {
        guard !items.isEmpty, let last = lastFetchedAt else { return false }
        return Date().timeIntervalSince(last) < ttl
    }

    var unreadCount: Int {
        items.filter { $0.isUnread }.count
    }

    var all: [NotificationItem] { items }

    var latest: NotificationItem? { items.first }

    // MARK: - Mutations

    func update(_ newItems: [NotificationItem]) {
        items = newItems
        lastFetchedAt = Date()
        notifyBadgeChanged()
    }

    func invalidate() {
        lastFetchedAt = nil
        notifyBadgeChanged()
    }

    func markRead(id: Int) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].status = 1
        }
        notifyBadgeChanged()
    }

    // MARK: - Badge Notification

    static let badgeChangedNotification = Notification.Name("NotificationCacheBadgeChanged")

    private func notifyBadgeChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NotificationCache.badgeChangedNotification,
                object: nil,
                userInfo: ["count": self.unreadCount]
            )
        }
    }
}
