import Foundation
import WidgetKit

/// App 与小组件之间的共享通道：把车况快照编码后写进 App Group 的
/// UserDefaults，再通知系统刷新小组件时间线。
/// 注意：这个文件要同时加入「主 App」和「小组件」两个 target。
enum SharedStore {
    static func save(_ snapshot: VehicleStatusSnapshot) {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID),
              let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: AppConstants.sharedStatusKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> VehicleStatusSnapshot? {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID),
              let data = defaults.data(forKey: AppConstants.sharedStatusKey) else {
            return nil
        }
        return try? JSONDecoder().decode(VehicleStatusSnapshot.self, from: data)
    }
}
