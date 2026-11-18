import Foundation

enum AuthError: LocalizedError {
    case invalidPhone
    case codeMismatch
    case notConfigured
    case provider(String)

    var errorDescription: String? {
        switch self {
        case .invalidPhone:
            return "手机号格式不正确，请输入 11 位手机号"
        case .codeMismatch:
            return "验证码不正确，请重新输入"
        case .notConfigured:
            return "登录服务尚未配置（缺少 Firebase 配置或后端地址）"
        case .provider(let message):
            return message
        }
    }
}

/// 短信验证码登录的抽象接口。
/// 默认提供两个实现：
///  - MockAuthProvider：本地演示，验证码固定 123456，不联网；
///  - FirebaseAuthProvider：真实短信（添加 Firebase SDK 后自动启用）。
/// 如果你要接自己的后端（阿里云/腾讯云短信），再写一个实现即可，
/// 业务代码完全不用改。
protocol AuthProvider {
    /// 向手机号发送验证码。
    /// 返回 verificationID：下一步校验时作为凭据传回
    /// （演示实现里仅作占位；Firebase 实现里是服务端返回的 ID）。
    func requestCode(phone: String) async throws -> String

    /// 校验验证码，成功后返回会话。
    func verify(phone: String, code: String, verificationID: String) async throws -> AuthSession
}
