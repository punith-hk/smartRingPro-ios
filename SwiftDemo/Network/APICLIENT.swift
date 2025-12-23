import Foundation

final class APIClient {

    static let shared = APIClient()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    func post<T: Codable>(
        endpoint: String,
        body: [String: Any],
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {

        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        logRequest(request)

        session.dataTask(with: request) { data, response, error in
            self.logResponse(data, response, error)

            if let _ = error {
                completion(.failure(.network))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decoding))
            }
        }.resume()
    }
    
    func get<T: Codable>(
            endpoint: String,
            responseType: T.Type,
            completion: @escaping (Result<T, NetworkError>) -> Void
        ) {

            guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
                completion(.failure(.invalidURL))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            logRequest(request)

            session.dataTask(with: request) { data, response, error in
                self.logResponse(data, response, error)

                if let _ = error {
                    completion(.failure(.network))
                    return
                }

                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(.decoding))
                }
            }.resume()
        }
}

// MARK: - Logging
private extension APIClient {

    func logRequest(_ request: URLRequest) {
        print("➡️ REQUEST:", request.url?.absoluteString ?? "")
        print("➡️ BODY:", String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")
    }

    func logResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        if let data = data {
            print("⬅️ RESPONSE:", String(data: data, encoding: .utf8) ?? "")
        }
        if let error = error {
            print("❌ ERROR:", error.localizedDescription)
        }
    }
}
