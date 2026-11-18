import SwiftUI

/// 外观设置：跟随系统 / 浅色 / 深色，作用于整个 App。
@MainActor
final class AppSettings: ObservableObject {
    enum Appearance: String, CaseIterable, Identifiable {
        case system = "跟随系统"
        case light = "浅色"
        case dark = "深色"

        var id: String { rawValue }
    }

    @Published var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appearance")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appearance") ?? ""
        appearance = Appearance(rawValue: saved) ?? .system
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
