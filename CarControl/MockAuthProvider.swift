import Foundation

/// 演示用登录实现：不发送真实短信，验证码固定为 123456。
/// 用途：在没有配置 Firebase / 自建后端之前，先把「发码 → 输码 → 登录」
/// 的整套流程跑通。上线前必须换成真实实现。
final class MockAuthProvider: AuthProvider {
    /// 演示验证码（仅 DEBUG 构建会在登录页提示用户）
    static let demoCode = "123456"

    func requestCode(phone: String) async throws -> String {
        // 模拟网络延迟，让 loading 状态可见
        try await Task.sleep(for: .milliseconds(600))
        return "mock-verification-id"
    }

    func verify(phone: String, code: String, verificationID: String) async throws -> AuthSession {
        guard code == Self.demoCode else {
            throw AuthError.codeMismatch
        }
        return AuthSession(phone: phone, token: "mock-token-\(UUID().uuidString)")
    }
}
