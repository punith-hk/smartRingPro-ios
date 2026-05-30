import Foundation

final class SymptomService {
    
    static let shared = SymptomService()
    private init() {}
    
    /// Fetch all symptoms for male and female body parts
    /// - Parameter completion: Callback with result
    func getAllSymptoms(
        completion: @escaping (Result<SymptomResponse, NetworkError>) -> Void
    ) {
        print("[SymptomService] 📥 Fetching symptoms...")
        
        let endpoint = APIEndpoints.getAllSymptoms
        APIClient.shared.get(
            endpoint: endpoint,
            responseType: SymptomResponse.self,
            completion: completion
        )
    }
}
