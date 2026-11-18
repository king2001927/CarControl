import SwiftUI

extension Color {
    /// 主题色（电光蓝），App 与小组件共用
    static let brand = Color(red: 0.05, green: 0.45, blue: 0.95)

    /// 电量较低时的警示色
    static let batteryLow = Color(red: 0.95, green: 0.35, blue: 0.25)
}

/// 电量对应的颜色：<20% 红，<50% 橙，其余品牌蓝
func batteryColor(_ percent: Int) -> Color {
    if percent < 20 { return .batteryLow }
    if percent < 50 { return .orange }
    return .brand
}
