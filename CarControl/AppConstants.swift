import Foundation

/// 全局常量：改 bundle id 和 App Group 时，这里必须同步修改。
enum AppConstants {
    /// App Group 标识。两个 target（主 App 和小组件）在
    /// Xcode › Signing & Capabilities 里都要添加 App Groups，
    /// 并且填同一个值，格式：group.你的域名.项目名
    static let appGroupID = "group.com.example.carcontrol"

    /// 小组件点击后打开 App 用的 URL Scheme（需在 Info.plist 注册）
    static let urlScheme = "carcontrol"

    /// 小组件共享数据在 App Group UserDefaults 里的键
    static let sharedStatusKey = "shared.vehicleStatus"

    /// 车辆名称在标准 UserDefaults 里的键
    static let carNameKey = "car.name"
}
