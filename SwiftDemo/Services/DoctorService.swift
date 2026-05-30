import Foundation

final class DoctorService {
    
    static let shared = DoctorService()
    private init() {}

    /// Fetch all departments (Specialists list screen)
    /// GET /api/departments
    func getDepartments(
        completion: @escaping (Result<[DepartmentItem], NetworkError>) -> Void
    ) {
        print("[DoctorService] 📥 Fetching all departments...")
        APIClient.shared.get(
            endpoint: APIEndpoints.departments,
            responseType: [DepartmentItem].self,
            completion: completion
        )
    }

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
