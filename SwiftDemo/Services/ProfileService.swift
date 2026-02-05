import Foundation

final class ProfileService {

    static let shared = ProfileService()
    private init() {}

    // MARK: - USER PROFILE

    /// Get logged-in user profile data
    func getUserProfile(
        userId: Int,
        completion: @escaping (Result<ProfileDataResponse, NetworkError>) -> Void
    ) {

        APIClient.shared.get(
            endpoint: APIEndpoints.patientProfile(id: userId),
            responseType: ProfileDataResponse.self,
            completion: completion
        )
    }

    /// Save / Update user profile (Multipart)
    func saveUserProfile(
        userId: Int,
        params: [String: String],
        profileImage: Data?,
        completion: @escaping (Result<AddProfileDataResponse, NetworkError>) -> Void
    ) {

        APIClient.shared.multipart(
            endpoint: APIEndpoints.patientProfile(id: userId),
            parameters: params,
            image: profileImage,
            responseType: AddProfileDataResponse.self,
            completion: completion
        )
    }

    // MARK: - FAMILY MEMBERS / DEPENDENTS

    /// Get all family members / dependents
    func getDependents(
        userId: Int,
        completion: @escaping (Result<DependentsResponse, NetworkError>) -> Void
    ) {

        APIClient.shared.get(
            endpoint: APIEndpoints.getDependents(userId: userId),
            responseType: DependentsResponse.self,
            completion: completion
        )
    }

    /// Add new family member (Multipart)
    func saveFamilyMember(
        userId: Int,
        params: [String: String],
        profileImage: Data?,
        completion: @escaping (Result<AddProfileDataResponse, NetworkError>) -> Void
    ) {

        APIClient.shared.multipart(
            endpoint: APIEndpoints.getDependents(userId: userId),
            parameters: params,
            image: profileImage,
            responseType: AddProfileDataResponse.self,
            completion: completion
        )
    }

    /// Update existing family member (Multipart)
    func updateFamilyMember(
        userId: Int,
        dependentId: Int,
        params: [String: String],
        profileImage: Data?,
        completion: @escaping (Result<AddProfileDataResponse, NetworkError>) -> Void
    ) {

        APIClient.shared.multipart(
            endpoint: APIEndpoints.updateFamilyMember(
                userId: userId,
                dependentId: dependentId
            ),
            parameters: params,
            image: profileImage,
            responseType: AddProfileDataResponse.self,
            completion: completion
        )
    }

    /// Delete family member
    /// Backend expects DELETE, but we use POST with `_method=DELETE`
    func deleteFamilyMember(
        userId: Int,
        dependentId: Int,
        completion: @escaping (Result<AddProfileDataResponse, NetworkError>) -> Void
    ) {

        APIClient.shared.post(
            endpoint: APIEndpoints.updateFamilyMember(
                userId: userId,
                dependentId: dependentId
            ),
            body: ["_method": "DELETE"],
            responseType: AddProfileDataResponse.self,
            completion: completion
        )
    }
}
