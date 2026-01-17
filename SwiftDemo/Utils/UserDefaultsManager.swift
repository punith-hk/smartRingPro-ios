import Foundation

final class UserDefaultsManager {

    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    private init() {}

    // MARK: - SAVE SESSION (Already correct)
    func saveOtpResponse(_ response: OtpResponse) {
        defaults.set(response.accessToken, forKey: "accessToken")
        defaults.set(response.user, forKey: "user")
        defaults.set(response.email, forKey: "email")
        defaults.set(response.role_code, forKey: "roleCode")
        defaults.set(response.mobile_number, forKey: "mobileNumber")
        defaults.set(response.id, forKey: "id")
        defaults.set(true, forKey: "isLoggedIn")
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
        defaults.set(false, forKey: "isLoggedIn")
    }

    // =====================================================
    // ✅ HELPER GETTERS (THIS IS THE IMPORTANT PART)
    // =====================================================

    var userId: Int {
        defaults.integer(forKey: "id")
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
}
