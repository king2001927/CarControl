import WidgetKit
import SwiftUI

/// 时间线条目：一次车况快照。
struct CarStatusEntry: TimelineEntry {
    let date: Date
    let snapshot: VehicleStatusSnapshot?
}

/// 时间线提供者：从 App Group 读取主 App 最近写入的车况。
/// 主 App 每次刷新都会调 WidgetCenter 重载时间线，这里的
/// 15 分钟策略只是兜底（防止 App 长时间不打开时小组件一直不更新）。
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CarStatusEntry {
        CarStatusEntry(date: Date(), snapshot: VehicleStatusSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (CarStatusEntry) -> Void) {
        let snapshot = SharedStore.load() ?? VehicleStatusSnapshot()
        completion(CarStatusEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CarStatusEntry>) -> Void) {
        let entry = CarStatusEntry(date: Date(), snapshot: SharedStore.load())
        let nextRefresh = Calendar.current.date(
            byAdding: .minute, value: 15, to: Date()
        ) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
