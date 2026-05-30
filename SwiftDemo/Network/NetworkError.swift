import Foundation

enum NetworkError: Error {
    case invalidURL
    case network
    case noData
    case decoding
    case encoding
    case unauthorized   // 401 — session expired, forced logout
}
