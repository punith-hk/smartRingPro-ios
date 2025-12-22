import Foundation

struct LoginResponse: Codable {
    let response: Int
    let message: MessageType?
    let user_id: Int?

    enum MessageType: Codable {
        case string(String)
        case array([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .string(str)
            } else if let arr = try? container.decode([String].self) {
                self = .array(arr)
            } else {
                self = .string("Unexpected error")
            }
        }

        func encode(to encoder: Encoder) throws {}
    }

    func formattedMessage() -> String {
        switch message {
        case .string(let msg):
            return msg
        case .array(let arr):
            return arr.joined(separator: "\n")
        default:
            return "Unexpected error"
        }
    }
}
