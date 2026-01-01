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

    // MARK: - POST (x-www-form-urlencoded)
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
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        logRequest(request)

        session.dataTask(with: request) { data, response, error in
            self.logResponse(data, response, error)

            if error != nil {
                completion(.failure(.network))
                return
            }

            guard let data else {
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

    // MARK: - GET
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

            if error != nil {
                completion(.failure(.network))
                return
            }

            guard let data else {
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

    // MARK: - MULTIPART (Profile / Family / Image Upload)
    func multipart<T: Codable>(
        endpoint: String,
        parameters: [String: String],
        image: Data?,
        imageKey: String = "image",
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {

        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        // TEXT PARAMETERS
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append(
                "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
            )
            body.append("\(value)\r\n")
        }

        // IMAGE
        if let imageData = image {
            body.append("--\(boundary)\r\n")
            body.append(
                "Content-Disposition: form-data; name=\"\(imageKey)\"; filename=\"profile.jpg\"\r\n"
            )
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        logRequest(request)

        session.dataTask(with: request) { data, response, error in
            self.logResponse(data, response, error)

            if error != nil {
                completion(.failure(.network))
                return
            }

            guard let data else {
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

// MARK: - LOGGING
private extension APIClient {

    func logRequest(_ request: URLRequest) {
        print("➡️ REQUEST:", request.url?.absoluteString ?? "")
        if let body = request.httpBody {
            print("➡️ BODY:", String(data: body, encoding: .utf8) ?? "")
        }
    }

    func logResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        if let data {
            print("⬅️ RESPONSE:", String(data: data, encoding: .utf8) ?? "")
        }
        if let error {
            print("❌ ERROR:", error.localizedDescription)
        }
    }
}

// MARK: - DATA EXTENSION (CRITICAL FOR MULTIPART)
private extension Data {

    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
