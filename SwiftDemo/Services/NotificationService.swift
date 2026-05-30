import Foundation

final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    // MARK: - Fetch Notifications

    /// GET /api/user/notifications?user_id={userId}&unread_only=true
    func getNotifications(
        userId: Int,
        completion: @escaping (Result<NotificationsResponse, NetworkError>) -> Void
    ) {
        APIClient.shared.get(
            endpoint: APIEndpoints.getNotifications(userId: userId),
            responseType: NotificationsResponse.self,
            completion: completion
        )
    }

    // MARK: - Mark as Read

    /// POST /api/user/notifications/{notificationId}/read
    func markAsRead(
        notificationId: Int,
        userId: Int,
        completion: @escaping (Result<MarkAsReadResponse, NetworkError>) -> Void
    ) {
        APIClient.shared.postJSON(
            endpoint: APIEndpoints.markNotificationRead(notificationId: notificationId),
            body: userId,
            responseType: MarkAsReadResponse.self,
            completion: completion
        )
    }

    // MARK: - Mark All as Read

    /// POST /api/user/notifications/read-all
    func markAllAsRead(
        userId: Int,
        completion: @escaping (Result<MarkAsReadResponse, NetworkError>) -> Void
    ) {
        APIClient.shared.post(
            endpoint: APIEndpoints.markAllNotificationsRead,
            body: ["user_id": userId],
            responseType: MarkAsReadResponse.self,
            completion: completion
        )
    }
}
