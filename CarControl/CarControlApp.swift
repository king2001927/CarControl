import SwiftUI

@main
struct CarControlApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var auth = AuthManager()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(settings)
                .preferredColorScheme(settings.colorScheme)
                .onOpenURL { url in
                    // 小组件点击会带 carcontrol:// 深链进来，
                    // 这里只做打开处理；需要定位到具体页面时在这里路由。
                    print("open url: \(url.absoluteString)")
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        switch auth.state {
        case .loading:
            ProgressView("正在恢复会话…")
        case .loggedOut:
            LoginView()
        case .loggedIn(let session):
            MainTabView(phone: session.phone)
        }
    }
}

struct MainTabView: View {
    let phone: String

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("车况", systemImage: "car.fill") }
            SettingsView(phone: phone)
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
        }
    }
}
