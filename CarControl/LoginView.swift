import SwiftUI

/// 短信验证码登录页：先输手机号拿验证码，再输验证码完成登录。
struct LoginView: View {
    @EnvironmentObject private var auth: AuthManager

    @State private var phone = ""
    @State private var code = ""
    @State private var verificationID = ""
    @State private var phase: Phase = .phone
    @State private var busy = false
    @State private var errorText: String?

    private enum Phase {
        case phone
        case code
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                if phase == .phone {
                    phoneSection
                } else {
                    codeSection
                }
                if let errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 区块

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 48))
                .foregroundColor(.brand)
            Text("CarControl")
                .font(.largeTitle.bold())
            Text("手机号验证码登录，随时掌握爱车状态")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 32)
    }

    private var phoneSection: some View {
        VStack(spacing: 12) {
            TextField("请输入手机号", text: $phone)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: phone) { newValue in
                    phone = String(newValue.filter(\.isNumber).prefix(11))
                }

            Button {
                Task { await sendCode() }
            } label: {
                Group {
                    if busy {
                        ProgressView().tint(.white)
                    } else {
                        Text("获取验证码").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(phoneValid ? Color.brand : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(busy || !phoneValid)

            #if !canImport(FirebaseAuth)
            Text("演示模式：验证码固定为 \(MockAuthProvider.demoCode)")
                .font(.footnote)
                .foregroundColor(.secondary)
            #endif
        }
    }

    private var codeSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("验证码已发送至 \(phone)")
                    .font(.subheadline)
            }

            TextField("请输入 6 位验证码", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: code) { newValue in
                    code = String(newValue.filter(\.isNumber).prefix(6))
                }

            Button {
                Task { await submitCode() }
            } label: {
                Group {
                    if busy {
                        ProgressView().tint(.white)
                    } else {
                        Text("登录").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(code.count == 6 ? Color.brand : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(busy || code.count != 6)

            Button("重新获取验证码") {
                phase = .phone
                errorText = nil
            }
            .font(.subheadline)
        }
    }

    // MARK: - 动作

    private var phoneValid: Bool {
        phone.range(of: #"^1\d{10}$"#, options: .regularExpression) != nil
    }

    private func sendCode() async {
        guard phoneValid else {
            errorText = AuthError.invalidPhone.localizedDescription
            return
        }
        busy = true
        errorText = nil
        do {
            verificationID = try await auth.requestCode(phone: phone)
            phase = .code
        } catch {
            errorText = error.localizedDescription
        }
        busy = false
    }

    private func submitCode() async {
        busy = true
        errorText = nil
        do {
            try await auth.verify(phone: phone, code: code, verificationID: verificationID)
        } catch {
            errorText = error.localizedDescription
            busy = false
        }
    }
}
