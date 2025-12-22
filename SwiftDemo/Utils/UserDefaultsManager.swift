import Foundation

final class UserDefaultsManager {

    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    private init() {}

    // ✅ SAVE SESSION (already correct)
    func saveOtpResponse(_ response: OtpResponse) {
        defaults.set(response.accessToken, forKey: "accessToken")
        defaults.set(response.user, forKey: "user")
        defaults.set(response.email, forKey: "email")
        defaults.set(response.role_code, forKey: "roleCode")
        defaults.set(response.mobile_number, forKey: "mobileNumber")
        defaults.set(response.id, forKey: "id")
        defaults.set(true, forKey: "isLoggedIn")
    }

    // ✅ ADD THIS (AUTO LOGIN CHECK)
    func isLoggedIn() -> Bool {
        return defaults.bool(forKey: "isLoggedIn")
    }

    // ✅ ADD THIS (FOR LOGOUT – LATER)
    func clearSession() {
        defaults.removeObject(forKey: "accessToken")
        defaults.removeObject(forKey: "user")
        defaults.removeObject(forKey: "email")
        defaults.removeObject(forKey: "roleCode")
        defaults.removeObject(forKey: "mobileNumber")
        defaults.removeObject(forKey: "id")
        defaults.set(false, forKey: "isLoggedIn")
    }
}
