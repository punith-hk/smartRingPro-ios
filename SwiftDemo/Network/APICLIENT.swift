import Foundation

final class APIClient {

    static let shared = APIClient()
    private init() {}

    // Endpoints that must NOT receive an Authorization header
    private let publicEndpoints: Set<String> = ["login", "verifyotp", "register"]

    // Refresh-token lock — one refresh at a time
    private var isRefreshing = false
    private let refreshLock = NSLock()

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
            completion(.failure(.invalidURL)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        injectAuth(&request, endpoint: endpoint)

        execute(request: request, responseType: responseType, retry: {
            self.post(endpoint: endpoint, body: body, responseType: responseType, completion: completion)
        }, completion: completion)
    }

    // MARK: - POST (JSON)
    func postJSON<T: Codable, B: Codable>(
        endpoint: String,
        body: B,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            completion(.failure(.invalidURL)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(.encoding)); return
        }
        injectAuth(&request, endpoint: endpoint)

        execute(request: request, responseType: responseType, retry: {
            self.postJSON(endpoint: endpoint, body: body, responseType: responseType, completion: completion)
        }, completion: completion)
    }

    // MARK: - GET
    func get<T: Codable>(
        endpoint: String,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let url = URL(string: APIEndpoints.baseURL + endpoint) else {
            completion(.failure(.invalidURL)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        injectAuth(&request, endpoint: endpoint)

        execute(request: request, responseType: responseType, retry: {
            self.get(endpoint: endpoint, responseType: responseType, completion: completion)
        }, completion: completion)
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
            completion(.failure(.invalidURL)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        if let imageData = image {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(imageKey)\"; filename=\"profile.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        injectAuth(&request, endpoint: endpoint)

        execute(request: request, responseType: responseType, retry: {
            self.multipart(endpoint: endpoint, parameters: parameters, image: image,
                           imageKey: imageKey, responseType: responseType, completion: completion)
        }, completion: completion)
    }

    // MARK: - Core execute
    private func execute<T: Codable>(
        request: URLRequest,
        responseType: T.Type,
        retry: @escaping () -> Void,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        logRequest(request)
        session.dataTask(with: request) { data, response, error in
            self.logResponse(data, response, error)

            if error != nil {
                completion(.failure(.network)); return
            }

            // 401 → refresh token, then retry original request once
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                self.handleUnauthorized(retry: retry, onFailure: {
                    completion(.failure(.unauthorized))
                })
                return
            }

            guard let data else {
                completion(.failure(.noData)); return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decoding))
            }
        }.resume()
    }

    // MARK: - Auth injection
    private func injectAuth(_ request: inout URLRequest, endpoint: String) {
        // Strip query string to get the base path for comparison
        let basePath = endpoint.components(separatedBy: "?").first ?? endpoint
        guard !publicEndpoints.contains(basePath) else { return }
        guard let token = UserDefaultsManager.shared.accessToken, !token.isEmpty else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    // MARK: - 401 / Token refresh
    private func handleUnauthorized(retry: @escaping () -> Void, onFailure: @escaping () -> Void) {
        refreshLock.lock()
        if isRefreshing {
            refreshLock.unlock()
            // Another refresh is already in flight — wait then retry with the new token
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { retry() }
            return
        }
        isRefreshing = true
        refreshLock.unlock()

        guard
            let oldToken = UserDefaultsManager.shared.accessToken,
            !oldToken.isEmpty,
            let url = URL(string: APIEndpoints.baseURL + APIEndpoints.refreshToken)
        else {
            finishRefresh()
            forceLogout()
            onFailure()
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(oldToken)", forHTTPHeaderField: "Authorization")
        logRequest(req)

        session.dataTask(with: req) { data, _, error in
            defer { self.finishRefresh() }
            self.logResponse(data, nil, error)

            guard
                let data,
                let result = try? JSONDecoder().decode(RefreshTokenResponse.self, from: data),
                let newToken = result.access_token,
                !newToken.isEmpty
            else {
                self.forceLogout()
                onFailure()
                return
            }

            UserDefaultsManager.shared.updateAccessToken(newToken)
            retry()
        }.resume()
    }

    private func finishRefresh() {
        refreshLock.lock()
        isRefreshing = false
        refreshLock.unlock()
    }

    private func forceLogout() {
        UserDefaultsManager.shared.clearSession()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .init("ForceLogout"), object: nil)
        }
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
