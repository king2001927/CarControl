import Foundation

/// 一次车辆状态的快照：主 App 刷新后写入 App Group，
/// 小组件从同一个 App Group 读出并渲染。全部字段 Codable，便于共享。
///
/// 基础字段（无默认 nil）为演示模式与云端模式共用；
/// 真实车况字段（可选）由「上汽云端」数据源填充，缺失时为 nil，
/// 与 MG Linker（Apache-2.0）公开的 getVehicleStatus 返回结构对应。
struct VehicleStatusSnapshot: Codable, Equatable {
    // MARK: - 基础字段
    var carName: String = "我的车"
    var batteryPercent: Int = 80      // 仪表主电量（纯电=电池%，混动/燃油=燃油%）
    var rangeKm: Int = 320            // 续航（km）
    var locked: Bool = true
    var address: String = "暂无位置"
    var updatedAt: Date = Date()

    // MARK: - 真实车况字段（上汽云端，缺失时为 nil）
    var fuelLevelPrc: Int?            // 燃油百分比
    var fuelRange: Int?               // 燃油续航 km
    var batteryPackPrc: Int?          // 电池包百分比
    var batteryPackRange: Int?        // 电池续航 km
    var drivingRange: Int?            // 综合续航 km
    var odometer: Int?                // 里程表 km
    var interiorTemperature: Double?  // 车内温度 ℃
    var exteriorTemperature: Int?     // 车外温度 ℃
    var vehicleBatteryVoltage: Int?   // 低压电池电压 V
    var chargeStatus: Int?            // 充电状态
    var chargeRemainingTime: Int?     // 充电剩余时间（分钟）
    var frontLeftTyrePressure: Int?   // 左前胎压 kPa
    var frontRightTyrePressure: Int?  // 右前胎压 kPa
    var rearLeftTyrePressure: Int?    // 左后胎压 kPa
    var rearRightTyrePressure: Int?   // 右后胎压 kPa
    var anyDoorOpen: Bool?            // 任意车门
    var bootOpen: Bool?               // 后备箱
    var windowOpen: Bool?             // 任意车窗
    var sunroofOpen: Bool?            // 天窗
    var climateOn: Bool?              // 空调
    var charging: Bool?               // 充电中
    var lightOn: Bool?                // 大灯
    var engineOn: Bool?               // 发动机
    var latitude: Double?             // 纬度
    var longitude: Double?            // 经度
    var dataSource: String?           // 数据来源标注（“演示数据”/“上汽云端”）

    // MARK: - UI 便捷计算属性（不参与编码）

    /// 是否有真实胎压数据
    var hasTyrePressures: Bool {
        frontLeftTyrePressure != nil || frontRightTyrePressure != nil
            || rearLeftTyrePressure != nil || rearRightTyrePressure != nil
    }

    /// 四轮胎压数组（供 UI 网格使用）
    var tyrePressures: [Int] {
        [
            frontLeftTyrePressure,
            frontRightTyrePressure,
            rearLeftTyrePressure,
            rearRightTyrePressure,
        ].compactMap { $0 }
    }

    /// 是否纯电优先展示（电池百分比有值时按电量展示）
    var isElectricDisplay: Bool {
        (batteryPackPrc ?? 0) > 0
    }
}

/// 登录成功后的会话。真实实现里 token 由后端 / Firebase 签发。
struct AuthSession: Codable, Equatable {
    let phone: String
    let token: String
}
