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
        case .systemLarge:
            largeView(snapshot)
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
                if snapshot.hasTyrePressures {
                    Text("胎压 " + snapshot.tyrePressures.map(String.init).joined(separator: "/") + " kPa")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text("更新 \(snapshot.updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    /// 大号：车名 + 电量环 + 四关键指标 + 四轮胎压 + 位置
    private func largeView(_ snapshot: VehicleStatusSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.carName)
                        .font(.headline)
                        .lineLimit(1)
                    Text("更新 \(snapshot.updatedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                batteryRing(snapshot.batteryPercent, size: 54)
            }

            HStack(spacing: 10) {
                metricTile("续航", "\(snapshot.rangeKm) km")
                metricTile("门锁", snapshot.locked ? "已锁" : "未锁")
                metricTile("车内", snapshot.interiorTemperature.map { String(format: "%.0f°", $0) } ?? "—")
                metricTile("里程", snapshot.odometer.map { "\($0) km" } ?? "—")
            }

            if snapshot.hasTyrePressures {
                HStack(spacing: 8) {
                    tyreTile("左前", snapshot.frontLeftTyrePressure)
                    tyreTile("右前", snapshot.frontRightTyrePressure)
                    tyreTile("左后", snapshot.rearLeftTyrePressure)
                    tyreTile("右后", snapshot.rearRightTyrePressure)
                }
            }

            if !snapshot.address.isEmpty {
                Label(snapshot.address, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
    }

    private func metricTile(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func tyreTile(_ label: String, _ value: Int?) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value.map(String.init) ?? "—")
                .font(.subheadline.bold())
                .foregroundColor(value.map { tyreColor($0) } ?? .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
