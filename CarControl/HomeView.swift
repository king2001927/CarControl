import SwiftUI

/// 首页：车况卡片。数据源由「设置 › 车辆数据源」决定（演示 / 上汽云端），
/// 每次刷新时经工厂重新取用，切换数据源后无需重启。
/// 每次刷新后同步到 App Group，桌面小组件随后更新。
struct HomeView: View {
    @AppStorage(AppConstants.carNameKey) private var carName = "我的车"

    @State private var snapshot = VehicleStatusSnapshot()
    @State private var isRefreshing = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let errorText {
                        Label(errorText, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .cardStyle()
                    }
                    batteryCard
                    statusGridCard
                    tyreCard
                    infoCard
                    locationCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(carName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await refresh() }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
            .task { await refresh() }
        }
    }

    // MARK: - 卡片

    /// 电量/油量 + 续航 + 充电状态
    private var batteryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label(snapshot.isElectricDisplay ? "电量" : "油量",
                      systemImage: snapshot.isElectricDisplay ? "battery.100percent" : "fuelpump.fill")
                    .font(.headline)
                Spacer()
                if snapshot.charging == true {
                    Label("充电中", systemImage: "bolt.fill")
                        .font(.footnote.bold())
                        .foregroundColor(.green)
                }
                Text("\(snapshot.batteryPercent)%")
                    .font(.title2.bold())
                    .foregroundColor(batteryColor(snapshot.batteryPercent))
            }
            Gauge(value: Double(snapshot.batteryPercent), in: 0...100) {
                EmptyView()
            }
            .tint(batteryColor(snapshot.batteryPercent))
            HStack {
                Text("预计续航")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(snapshot.rangeKm) km")
                    .font(.headline)
            }
            if let fuel = snapshot.fuelLevelPrc, !snapshot.isElectricDisplay {
                HStack {
                    Text("燃油")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(fuel)% · 油续航 \(snapshot.fuelRange ?? 0) km")
                        .font(.subheadline)
                }
            }
        }
        .cardStyle()
    }

    /// 车辆开关状态网格（对应 MGControl 车况卡片：门锁门窗等）
    private var statusGridCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("车辆状态")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                statusChip("门锁", snapshot.locked, icon: snapshot.locked ? "lock.fill" : "lock.open.fill",
                           on: "已锁", off: "未锁")
                statusChip("车门", snapshot.anyDoorOpen ?? false, icon: "car.side.fill", on: "已开", off: "关闭")
                statusChip("车窗", snapshot.windowOpen ?? false, icon: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left", on: "已开", off: "关闭")
                statusChip("后备箱", snapshot.bootOpen ?? false, icon: "car.side.rear.fill", on: "已开", off: "关闭")
                statusChip("天窗", snapshot.sunroofOpen ?? false, icon: "arrow.up.right.circle", on: "已开", off: "关闭")
                statusChip("空调", snapshot.climateOn ?? false, icon: "snowflake", on: "开启", off: "关闭")
                statusChip("大灯", snapshot.lightOn ?? false, icon: "light.max", on: "开启", off: "关闭")
                statusChip("发动机", snapshot.engineOn ?? false, icon: "engine.combustion", on: "运转", off: "停止")
            }
        }
        .cardStyle()
    }

    private func statusChip(_ title: String, _ active: Bool, icon: String, on: String, off: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(active ? .brand : .secondary)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            Text(active ? on : off)
                .font(.caption2)
                .foregroundColor(active ? .green : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// 胎压（对应 MGControl 车况卡片的胎压展示）
    private var tyreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("胎压 (kPa)")
                .font(.headline)
            if snapshot.hasTyrePressures {
                let values = [
                    ("左前", snapshot.frontLeftTyrePressure),
                    ("右前", snapshot.frontRightTyrePressure),
                    ("左后", snapshot.rearLeftTyrePressure),
                    ("右后", snapshot.rearRightTyrePressure),
                ]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(values, id: \.0) { item in
                        VStack(spacing: 4) {
                            Text(item.0)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(item.1.map(String.init) ?? "—")
                                .font(.headline)
                                .foregroundColor(item.1.map { tyreColor($0) } ?? .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                Text("暂无胎压数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }

    /// 里程 / 温度 / 低压电池
    private var infoCard: some View {
        VStack(spacing: 10) {
            infoRow("里程", snapshot.odometer.map { "\($0) km" } ?? "—", icon: "road.lanes")
            infoRow("车内温度", snapshot.interiorTemperature.map { String(format: "%.0f ℃", $0) } ?? "—", icon: "thermometer.medium")
            infoRow("车外温度", snapshot.exteriorTemperature.map { "\($0) ℃" } ?? "—", icon: "sun.max")
            infoRow("低压电池", snapshot.vehicleBatteryVoltage.map { "\($0) V" } ?? "—", icon: "minus.plus.batteryblock")
            if let minutes = snapshot.chargeRemainingTime, minutes > 0 {
                infoRow("充电剩余", "\(minutes) 分钟", icon: "bolt.car")
            }
        }
        .cardStyle()
    }

    private func infoRow(_ title: String, _ value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.brand)
                .frame(width: 28)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.brand)
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.address)
                        .font(.subheadline)
                    Text("更新于 \(snapshot.updatedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            HStack {
                Spacer()
                Text("数据来源：\(snapshot.dataSource ?? "—")")
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .cardStyle()
    }

    // MARK: - 刷新

    private func refresh() async {
        isRefreshing = true
        errorText = nil
        do {
            let service = VehicleServiceFactory.current()
            var fresh = try await service.refresh()
            fresh.carName = carName
            snapshot = fresh
            SharedStore.save(fresh)
            if #available(iOS 16.2, *) {
                LiveActivityManager.update(
                    with: fresh,
                    enabled: UserDefaults.standard.bool(forKey: "liveActivity.enabled")
                )
            }
        } catch {
            errorText = error.localizedDescription
        }
        isRefreshing = false
    }
}

/// 胎压颜色：过低/过高警示
private func tyreColor(_ kPa: Int) -> Color {
    if kPa < 200 || kPa > 290 { return .batteryLow }
    if kPa < 220 || kPa > 270 { return .orange }
    return .primary
}

/// 卡片通用样式
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
