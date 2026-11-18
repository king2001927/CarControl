import SwiftUI

/// 设置页：车辆数据源、车辆名称、外观、关于、退出登录。
struct SettingsView: View {
    let phone: String

    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var settings: AppSettings
    @AppStorage(AppConstants.carNameKey) private var carName = "我的车"

    @State private var dataSource: VehicleDataSource = .demo
    @State private var vin = ""
    @State private var cloudToken = ""
    @State private var savedNotice: String?

    var body: some View {
        NavigationStack {
            Form {
                vehicleSection
                dataSourceSection
                appearanceSection
                accountSection
                aboutSection
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadVehicleConfig)
        }
    }

    // MARK: - 区块

    private var vehicleSection: some View {
        Section("车辆") {
            TextField("车辆名称", text: $carName)
                .onSubmit { saveCarNameToSharedStore() }
        }
    }

    private var dataSourceSection: some View {
        Section {
            Picker("数据源", selection: $dataSource) {
                ForEach(VehicleDataSource.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            if dataSource == .saiCloud {
                TextField("车架号 VIN（17 位）", text: $vin)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .font(.body.monospaced())
                TextField("ACCESS_TOKEN（以 -prod_SAIC 结尾）", text: $cloudToken)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.footnote.monospaced())
                Button("保存车辆凭证") {
                    saveVehicleConfig()
                }
                .disabled(!credentialValid)
                if let savedNotice {
                    Text(savedNotice)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("车辆数据源")
        } footer: {
            if dataSource == .saiCloud {
                Text("「上汽云端」直接读取上汽斑马车联网的车况接口（参考 MG Linker，Apache-2.0）。ACCESS_TOKEN 需从官方 App 抓包获得，凭据仅保存在本机，不经过任何第三方。演示数据无需配置。")
            }
        }
    }

    private var appearanceSection: some View {
        Section("外观") {
            Picker("外观", selection: $settings.appearance) {
                ForEach(AppSettings.Appearance.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }
    }

    private var accountSection: some View {
        Section("账号") {
            LabeledContent("登录手机号", value: maskedPhone)
            Button("退出登录", role: .destructive) {
                auth.logout()
            }
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            LabeledContent("版本", value: "0.2.0")
            Text("车辆状态接口与字段结构参考 MG Linker（Apache-2.0，见 NOTICE.md）。演示模式下为本地模拟数据。")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 逻辑

    private var credentialValid: Bool {
        vin.count == 17 && cloudToken.hasSuffix("-prod_SAIC")
    }

    private var maskedPhone: String {
        guard phone.count == 11 else { return phone }
        return "\(phone.prefix(3))****\(phone.suffix(4))"
    }

    private func loadVehicleConfig() {
        let saved = UserDefaults.standard.string(forKey: VehicleServiceFactory.sourceKey) ?? ""
        dataSource = VehicleDataSource(rawValue: saved) ?? .demo
        vin = UserDefaults.standard.string(forKey: VehicleServiceFactory.vinKey) ?? ""
        cloudToken = UserDefaults.standard.string(forKey: VehicleServiceFactory.tokenKey) ?? ""
    }

    private func saveVehicleConfig() {
        UserDefaults.standard.set(dataSource.rawValue, forKey: VehicleServiceFactory.sourceKey)
        UserDefaults.standard.set(vin, forKey: VehicleServiceFactory.vinKey)
        UserDefaults.standard.set(cloudToken, forKey: VehicleServiceFactory.tokenKey)
        savedNotice = dataSource == .saiCloud
            ? "已保存 ✓ 回首页点刷新即可拉取真实车况"
            : "已保存 ✓ 当前使用演示数据"
    }

    private func saveCarNameToSharedStore() {
        var snapshot = SharedStore.load() ?? VehicleStatusSnapshot()
        snapshot.carName = carName
        SharedStore.save(snapshot)
    }
}
