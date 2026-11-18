import Foundation

/// 车辆数据源抽象。这里目前只有「读取车况」，后续可以把
/// 远程车控（锁车/解锁/空调等）加进来。
///
/// 重要：演示项目只提供 Mock 实现（本地模拟数据）。
/// 接入真实车辆数据时，请使用你**合法获得**的接口——
/// 例如官方开放 API、OBD 盒子或你自己的车联网服务，
/// 然后写一个实现本协议的类替换掉 Mock 即可，UI 不用改。
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
        last = next
        return next
    }
}
