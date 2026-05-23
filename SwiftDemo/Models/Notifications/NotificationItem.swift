import Foundation

struct NotificationItem: Codable {
    let id: Int
    let user_id: Int
    let timestamp: Int64
    let sent: Int
    var status: Int          // 0 = unread, 1 = read
    let title: String?
    let message: String
    let vitals: String?      // JSON string e.g. {"heart_rate":"125","blood_oxygen":"98"}
    let created_at: String?
    let updated_at: String?

    // MARK: - Computed

    var isUnread: Bool { status == 0 }

    /// Returns provided title or auto-generates from message content
    var resolvedTitle: String {
        if let t = title, !t.trimmingCharacters(in: .whitespaces).isEmpty { return t }
        let msg = message.lowercased()
        if msg.contains("blood sugar") || msg.contains("glucose") { return "Blood Sugar Alert" }
        if msg.contains("hrv")                                     { return "HRV Alert" }
        if msg.contains("heart rate")                              { return "Heart Rate Alert" }
        if msg.contains("blood pressure")                          { return "Blood Pressure Alert" }
        if msg.contains("blood oxygen") || msg.contains("oxygen")  { return "Blood Oxygen Alert" }
        if msg.contains("temperature")                             { return "Temperature Alert" }
        if msg.contains("vitals")                                  { return "Vitals Alert" }
        return "Health Alert"
    }

    /// Parsed vitals dictionary from JSON string
    var parsedVitals: [String: String] {
        guard let json = vitals,
              !json.trimmingCharacters(in: .whitespaces).isEmpty,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return [:] }
        return dict
    }

    /// Formatted timestamp string: "23 May 2026, 02:15 PM"
    var formattedTime: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let fmt = DateFormatter()
        fmt.dateFormat = "dd MMM yyyy, hh:mm a"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }
}

struct NotificationsResponse: Codable {
    let message: String
    let data: [NotificationItem]
}

struct MarkAsReadResponse: Codable {
    let message: String
}
