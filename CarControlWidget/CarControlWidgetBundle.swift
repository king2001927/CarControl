import WidgetKit
import SwiftUI

/// 小组件入口：一个 WidgetBundle，以后可以加更多种小组件。
@main
struct CarControlWidgetBundle: WidgetBundle {
    var body: some Widget {
        CarStatusWidget()
    }
}

/// 车况小组件：小号 / 中号。
struct CarStatusWidget: Widget {
    private let kind = "CarStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CarStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("车况")
        .description("随时查看电量、续航和门锁状态，点击回到 App。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
