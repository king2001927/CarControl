import SwiftUI

/// 首页：车况卡片。数据来自 VehicleService（默认模拟数据），
/// 每次刷新后同步到 App Group，桌面小组件随后更新。
struct HomeView: View {
    let service: any VehicleService

    @AppStorage(AppConstants.carNameKey) private var carName = "我的车"

    @State private var snapshot = VehicleStatusSnapshot()
    @State private var isRefreshing = false
    @State private var errorText: String?

    init(service: any VehicleService = MockVehicleService()) {
        self.service = service
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    batteryCard
                    statusCard
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

    private var batteryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label("电量", systemImage: "battery.100percent")
                    .font(.headline)
                Spacer()
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
        }
        .cardStyle()
    }

    private var statusCard: some View {
        HStack {
            Label("门锁", systemImage: "lock.fill")
                .font(.headline)
            Spacer()
            Label(
                snapshot.locked ? "已锁定" : "已解锁",
                systemImage: snapshot.locked ? "lock.circle.fill" : "lock.open.fill"
            )
            .font(.headline)
            .foregroundColor(snapshot.locked ? .green : .orange)
        }
        .cardStyle()
    }

    private var locationCard: some View {
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
        .cardStyle()
    }

    // MARK: - 刷新

    private func refresh() async {
        isRefreshing = true
        errorText = nil
        do {
            var fresh = try await service.refresh()
            fresh.carName = carName
            snapshot = fresh
            SharedStore.save(fresh)
        } catch {
            errorText = "刷新失败：\(error.localizedDescription)"
        }
        isRefreshing = false
    }
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
