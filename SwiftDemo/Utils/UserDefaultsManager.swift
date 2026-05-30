import Foundation

final class UserDefaultsManager {

    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    private init() {}

    // MARK: - SAVE SESSION
    func saveOtpResponse(_ response: OtpResponse) {
        defaults.set(response.tokenData?.access_token, forKey: "accessToken")
        defaults.set(response.user, forKey: "user")
        defaults.set(response.email, forKey: "email")
        defaults.set(response.role_code, forKey: "roleCode")
        defaults.set(response.mobile_number, forKey: "mobileNumber")
        defaults.set(response.id, forKey: "id")  // Regular ID for most APIs
        defaults.set(response.user_id, forKey: "user_id")  // Actual user_id for FCM
        defaults.set(true, forKey: "isLoggedIn")
    }

    func updateAccessToken(_ token: String) {
        defaults.set(token, forKey: "accessToken")
    }

    // MARK: - SESSION CHECK
    func isLoggedIn() -> Bool {
        return defaults.bool(forKey: "isLoggedIn")
    }

    // MARK: - LOGOUT
    func clearSession() {
        defaults.removeObject(forKey: "accessToken")
        defaults.removeObject(forKey: "user")
        defaults.removeObject(forKey: "email")
        defaults.removeObject(forKey: "roleCode")
        defaults.removeObject(forKey: "mobileNumber")
        defaults.removeObject(forKey: "id")
        defaults.removeObject(forKey: "user_id")  // Clear FCM user_id
        defaults.set(false, forKey: "isLoggedIn")
        
        // Reset FCM token sent flag so it gets sent again on next login
        FCMService.resetTokenSentFlag()
    }

    // =====================================================
    // ✅ HELPER GETTERS (THIS IS THE IMPORTANT PART)
    // =====================================================

    var userId: Int {
        defaults.integer(forKey: "id")
    }
    
    // For FCM API only - uses actual user_id from OTP response
    var fcmUserId: Int {
        defaults.integer(forKey: "user_id")
    }

    var accessToken: String? {
        defaults.string(forKey: "accessToken")
    }

    var email: String? {
        defaults.string(forKey: "email")
    }

    var mobileNumber: String? {
        defaults.string(forKey: "mobileNumber")
    }

    var roleCode: String? {
        defaults.string(forKey: "roleCode")
    }

    var userName: String? {
        defaults.string(forKey: "user")
    }

    // MARK: - Terms & Conditions
    func setTermsAccepted(_ accepted: Bool) {
        defaults.set(accepted, forKey: "termsConditionsAccepted")
    }

    func isTermsAccepted() -> Bool {
        return defaults.bool(forKey: "termsConditionsAccepted")
    }
    
    // MARK: - Profile Data
    var profileName: String? {
        get { defaults.string(forKey: "profileName") }
        set { defaults.set(newValue, forKey: "profileName") }
    }
    
    var profilePhotoUrl: String? {
        get { defaults.string(forKey: "profilePhotoUrl") }
        set { defaults.set(newValue, forKey: "profilePhotoUrl") }
    }
    
    var profileAge: Int {
        get { defaults.integer(forKey: "profileAge") }
        set { defaults.set(newValue, forKey: "profileAge") }
    }
    
    var profileGender: String? {
        get { defaults.string(forKey: "profileGender") }
        set { defaults.set(newValue, forKey: "profileGender") }
    }

    var profileHeight: Double {
        get { defaults.double(forKey: "user_height") }
        set { defaults.set(newValue, forKey: "user_height") }
    }

    var profileWeight: Double {
        get { defaults.double(forKey: "user_weight") }
        set { defaults.set(newValue, forKey: "user_weight") }
    }

    /// The `user_id` field returned inside ProfileData — used when calling profile update API.
    var profileUserId: Int {
        get { defaults.integer(forKey: "profile_user_id") }
        set { defaults.set(newValue, forKey: "profile_user_id") }
    }

    func saveProfileData(
        name: String,
        photoUrl: String,
        age: Int = 0,
        gender: String? = nil,
        phone: String? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        profileUserId: Int? = nil
    ) {
        defaults.set(name, forKey: "profileName")
        defaults.set(photoUrl, forKey: "profilePhotoUrl")
        if age > 0 {
            defaults.set(age, forKey: "profileAge")
        }
        if let gender = gender, !gender.isEmpty {
            defaults.set(gender, forKey: "profileGender")
        }
        if let phone = phone, !phone.isEmpty {
            defaults.set(phone, forKey: "mobileNumber")
        }
        if let h = height, h > 0 {
            defaults.set(h, forKey: "user_height")
        }
        if let w = weight, w > 0 {
            defaults.set(w, forKey: "user_weight")
        }
        if let uid = profileUserId, uid > 0 {
            defaults.set(uid, forKey: "profile_user_id")
        }
    }
    
    func clearProfileData() {
        defaults.removeObject(forKey: "profileName")
        defaults.removeObject(forKey: "profilePhotoUrl")
        defaults.removeObject(forKey: "profileAge")
        defaults.removeObject(forKey: "profileGender")
    }
}
