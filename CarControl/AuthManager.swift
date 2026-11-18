import Foundation

/// 登录状态管理中心：持有当前会话、负责登录/登出/恢复。
/// 会话存本地（演示项目用 UserDefaults；正式项目建议放 Keychain）。
@MainActor
final class AuthManager: ObservableObject {
    enum State: Equatable {
        case loading
        case loggedOut
        case loggedIn(AuthSession)
    }

    @Published private(set) var state: State = .loading

    private let provider: any AuthProvider
    private let sessionKey = "auth.session"

    init(provider: (any AuthProvider)? = nil) {
        self.provider = provider ?? Self.defaultProvider()
        restore()
    }

    /// 有 Firebase SDK 就用真实短信，否则用演示实现。
    static func defaultProvider() -> any AuthProvider {
        #if canImport(FirebaseAuth)
        return FirebaseAuthProvider()
        #else
        return MockAuthProvider()
        #endif
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(AuthSession.self, from: data) else {
            state = .loggedOut
            return
        }
        state = .loggedIn(session)
    }

    func requestCode(phone: String) async throws -> String {
        try await provider.requestCode(phone: phone)
    }

    func verify(phone: String, code: String, verificationID: String) async throws {
        let session = try await provider.verify(
            phone: phone, code: code, verificationID: verificationID
        )
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
        state = .loggedIn(session)
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        state = .loggedOut
    }
}
