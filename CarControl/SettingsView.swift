import SwiftUI

/// 设置页：车辆名称、外观、关于、退出登录。
struct SettingsView: View {
    let phone: String

    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var settings: AppSettings
    @AppStorage(AppConstants.carNameKey) private var carName = "我的车"

    var body: some View {
        NavigationStack {
            Form {
                Section("车辆") {
                    TextField("车辆名称", text: $carName)
                        .onSubmit { saveCarNameToSharedStore() }
                }

                Section("外观") {
                    Picker("外观", selection: $settings.appearance) {
                        ForEach(AppSettings.Appearance.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Section("账号") {
                    LabeledContent("登录手机号", value: maskedPhone)
                    Button("退出登录", role: .destructive) {
                        auth.logout()
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "0.1.0")
                    Text("演示项目：车辆数据为本地模拟，短信登录默认走演示验证码。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// 手机号脱敏显示：138****5678
    private var maskedPhone: String {
        guard phone.count == 11 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }

    private func saveCarNameToSharedStore() {
        var snapshot = SharedStore.load() ?? VehicleStatusSnapshot()
        snapshot.carName = carName
        SharedStore.save(snapshot)
    }
}
