import Foundation

enum NetworkError: Error {
    case invalidURL
    case network
    case noData
    case decoding
}
