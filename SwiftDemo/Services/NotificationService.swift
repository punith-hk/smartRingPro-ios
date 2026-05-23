import Foundation

final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    // MARK: - Fetch Notifications

    /// GET /api/notifications/{userId}
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

    private struct MarkAsReadBody: Codable {
        let id: Int
        let user_id: Int
    }

    /// POST /api/notifications/mark-as-read
    func markAsRead(
        notificationId: Int,
        userId: Int,
        completion: @escaping (Result<MarkAsReadResponse, NetworkError>) -> Void
    ) {
        let body = MarkAsReadBody(id: notificationId, user_id: userId)
        APIClient.shared.postJSON(
            endpoint: APIEndpoints.markNotificationRead,
            body: body,
            responseType: MarkAsReadResponse.self,
            completion: completion
        )
    }
}
