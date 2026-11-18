import Foundation

/// 一次车辆状态的快照：主 App 刷新后写入 App Group，
/// 小组件从同一个 App Group 读出并渲染。全部字段 Codable，便于共享。
struct VehicleStatusSnapshot: Codable, Equatable {
    var carName: String = "我的车"
    var batteryPercent: Int = 80
    var rangeKm: Int = 320
    var locked: Bool = true
    var address: String = "暂无位置"
    var updatedAt: Date = Date()
}

/// 登录成功后的会话。真实实现里 token 由后端 / Firebase 签发。
struct AuthSession: Codable, Equatable {
    let phone: String
    let token: String
}
