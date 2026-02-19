import Foundation

final class DoctorService {
    
    static let shared = DoctorService()
    private init() {}
    
    /// Fetch doctors for a specific department
    /// - Parameters:
    ///   - departmentId: Department ID
    ///   - completion: Callback with result
    func getDoctors(
        departmentId: Int,
        completion: @escaping (Result<DoctorResponse, NetworkError>) -> Void
    ) {
        print("[DoctorService] 📥 Fetching doctors for department \(departmentId)...")
        
        APIClient.shared.get(
            endpoint: APIEndpoints.getDoctors(departmentId: departmentId),
            responseType: DoctorResponse.self,
            completion: completion
        )
    }
}
