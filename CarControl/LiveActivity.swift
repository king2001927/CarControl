import ActivityKit
import SwiftUI
import WidgetKit

/// 实时活动属性：车名 + 可变车况
struct CarStatusAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var batteryPercent: Int
        var rangeKm: Int
        var locked: Bool
        var updatedAt: Date
    }

    var carName: String
}

/// 灵动岛 / 锁屏实时活动（iOS 16.2+，在主 App 内声明，无需扩展 target）
@available(iOS 16.2, *)
struct CarStatusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CarStatusAttributes.self) { context in
            // 锁屏与通知横幅
            HStack(spacing: 16) {
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundColor(.brand)
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.carName)
                        .font(.headline)
                        .lineLimit(1)
                    Text("更新 \(context.state.updatedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(context.state.batteryPercent)%")
                        .font(.title2.bold())
                        .foregroundColor(batteryColor(context.state.batteryPercent))
                    Text("续航 \(context.state.rangeKm) km")
                        .font(.caption)
                }
                Image(systemName: context.state.locked ? "lock.fill" : "lock.open.fill")
                    .foregroundColor(context.state.locked ? .green : .orange)
            }
            .padding(16)
            .activityBackgroundTint(Color(.systemGray6))
            .activitySystemActionForegroundColor(Color.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundColor(.brand)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 2) {
                        Text("\(context.state.batteryPercent)%")
                            .font(.title2.bold())
                            .foregroundColor(batteryColor(context.state.batteryPercent))
                        Text("\(context.state.rangeKm) km")
                            .font(.caption2)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Image(systemName: context.state.locked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(context.state.locked ? .green : .orange)
                        Text(context.state.locked ? "已锁定" : "已解锁")
                            .font(.caption)
                        Spacer()
                        Text("更新 \(context.state.updatedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "car.fill")
            } compactTrailing: {
                Text("\(context.state.batteryPercent)%")
            } minimal: {
                Image(systemName: context.state.locked ? "lock.fill" : "car.fill")
            }
        }
    }
}

/// 实时活动的开启 / 更新 / 结束。
@available(iOS 16.2, *)
enum LiveActivityManager {
    /// 用最新车况更新实时活动；enabled 为 false 时结束所有活动。
    static func update(with snapshot: VehicleStatusSnapshot, enabled: Bool) {
        if !enabled {
            for activity in Activity<CarStatusAttributes>.activities {
                Task { await activity.end(dismissalPolicy: .immediate) }
            }
            return
        }
        let state = CarStatusAttributes.ContentState(
            batteryPercent: snapshot.batteryPercent,
            rangeKm: snapshot.rangeKm,
            locked: snapshot.locked,
            updatedAt: snapshot.updatedAt
        )
        if let current = Activity<CarStatusAttributes>.activities.first {
            Task { await current.update(using: state) }
        } else {
            let attributes = CarStatusAttributes(carName: snapshot.carName)
            let content = ActivityContent(state: state, staleDate: nil)
            Task {
                do {
                    _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
                } catch {
                    // 用户未授权或系统繁忙时静默失败
                }
            }
        }
    }
}
