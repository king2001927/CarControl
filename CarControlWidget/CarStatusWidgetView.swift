import SwiftUI
import WidgetKit

/// 小组件渲染：小号显示电量环 + 续航；中号额外显示门锁、位置和更新时间。
/// 点击整个小组件会打开主 App（carcontrol:// 深链）。
struct CarStatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CarStatusEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            content(snapshot)
                .widgetBackground(Color(.systemBackground))
                .widgetURL(URL(string: "\(AppConstants.urlScheme)://open"))
        } else {
            emptyView
                .widgetBackground(Color(.systemBackground))
        }
    }

    // MARK: - 内容

    @ViewBuilder
    private func content(_ snapshot: VehicleStatusSnapshot) -> some View {
        switch family {
        case .systemSmall:
            smallView(snapshot)
        default:
            mediumView(snapshot)
        }
    }

    private func smallView(_ snapshot: VehicleStatusSnapshot) -> some View {
        VStack(spacing: 8) {
            batteryRing(snapshot.batteryPercent, size: 64)
            Text("\(snapshot.rangeKm) km")
                .font(.caption.bold())
            Text("更新 \(snapshot.updatedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func mediumView(_ snapshot: VehicleStatusSnapshot) -> some View {
        HStack(spacing: 16) {
            batteryRing(snapshot.batteryPercent, size: 72)
            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.carName)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Image(systemName: snapshot.locked ? "lock.fill" : "lock.open.fill")
                        .foregroundColor(snapshot.locked ? .green : .orange)
                    Text(snapshot.locked ? "已锁定" : "已解锁")
                        .font(.subheadline)
                }
                Text("续航 \(snapshot.rangeKm) km")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("更新 \(snapshot.updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    /// 电量圆环
    private func batteryRing(_ percent: Int, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(
                    batteryColor(percent),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(percent)")
                    .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                Text("%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("打开 App 同步车况")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// 小组件背景：iOS 17 起系统要求用 containerBackground，
/// 旧系统退回普通 background。
extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            background(color)
        }
    }
}
