import Foundation

// 只有把 Firebase SDK（FirebaseAuth）通过 SPM 加进工程后，
// 下面这段代码才会被编译；没加时自动使用 MockAuthProvider。
#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseCore

/// 真实短信验证码登录（Firebase Phone Auth）。
///
/// 启用步骤（详见构建指南）：
/// 1. Xcode › File › Add Package Dependencies，添加
///    https://github.com/firebase/firebase-ios-sdk 的 FirebaseAuth 模块；
/// 2. 把 GoogleService-Info.plist 拖进主 App target；
/// 3. Firebase 控制台 Authentication 里开启「电话」登录方式；
/// 4. 真机上首次登录需要 APNs：如果短信发不出去，
///    在 AppDelegate/init 里调用 Auth.auth().setAPNSToken(...)。
final class FirebaseAuthProvider: AuthProvider {
    init() {
        if FirebaseApp.app() == nil {
            try? FirebaseApp.configure()
        }
    }

    func requestCode(phone: String) async throws -> String {
        guard FirebaseApp.app() != nil else {
            throw AuthError.notConfigured
        }
        do {
            // 注意：国内网络访问 Google 服务可能不稳定，
            // 如短信始终收不到，改用自建后端（server/ 模板）。
            return try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phone, uiDelegate: nil)
        } catch {
            throw AuthError.provider(error.localizedDescription)
        }
    }

    func verify(phone: String, code: String, verificationID: String) async throws -> AuthSession {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        do {
            let result = try await Auth.auth().signIn(with: credential)
            let token = try await result.user.getIDToken()
            return AuthSession(phone: phone, token: token)
        } catch {
            throw AuthError.provider(error.localizedDescription)
        }
    }
}
#endif
