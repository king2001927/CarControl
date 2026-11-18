import Foundation

/// 车辆数据源抽象。这里目前只有「读取车况」，后续可以把
/// 远程车控（锁车/解锁/空调等）加进来。
protocol VehicleService: AnyObject {
    func refresh() async throws -> VehicleStatusSnapshot
}

/// 演示数据源：返回缓慢变化的模拟车况，用来把 App 和小组件跑通。
final class MockVehicleService: VehicleService {
    private let sampleAddresses = [
        "模拟位置 · 地下车库 A-12",
        "模拟位置 · 公司园区 B-03",
        "模拟位置 · 家楼下 C-21",
    ]

    private var last = VehicleStatusSnapshot()

    func refresh() async throws -> VehicleStatusSnapshot {
        // 模拟网络延迟
        try await Task.sleep(for: .milliseconds(700))

        var next = last
        let delta = Int.random(in: -1...1)
        next.batteryPercent = max(5, min(100, next.batteryPercent + delta))
        next.rangeKm = next.batteryPercent * 4
        next.locked = Bool.random()
        next.address = sampleAddresses.randomElement() ?? "未知位置"
        next.updatedAt = Date()

        // 模拟真实字段，让完整界面在演示模式下也能预览
        next.batteryPackPrc = next.batteryPercent
        next.batteryPackRange = next.rangeKm
        next.drivingRange = next.rangeKm
        next.odometer = Int.random(in: 8000...12000)
        next.interiorTemperature = Double(Int.random(in: 18...28))
        next.exteriorTemperature = Int.random(in: 5...30)
        next.vehicleBatteryVoltage = Int.random(in: 11...14)
        next.frontLeftTyrePressure = Int.random(in: 225...255)
        next.frontRightTyrePressure = Int.random(in: 225...255)
        next.rearLeftTyrePressure = Int.random(in: 225...255)
        next.rearRightTyrePressure = Int.random(in: 225...255)
        next.anyDoorOpen = Bool.random()
        next.bootOpen = Bool.random()
        next.windowOpen = Bool.random()
        next.sunroofOpen = false
        next.climateOn = Bool.random()
        next.charging = Bool.random()
        next.lightOn = false
        next.engineOn = false
        next.dataSource = "演示数据"

        last = next
        return next
    }
}
