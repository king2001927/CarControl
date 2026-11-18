import BackgroundTasks
import Foundation
import UIKit

/// 后台自动刷新：预约 BGAppRefreshTask，由 iOS 调度（执行时机不保证）。
final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()

    /// 与 project.yml 里 Info.plist 的 BGTaskSchedulerPermittedIdentifiers 一致
    private let identifier = "com.example.carcontrol.refresh"

    private init() {}

    /// 在 didFinishLaunching 里调用（必须在启动完成前注册）
    func registerAndSchedule() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            self.handle(task as? BGAppRefreshTask)
        }
        schedule()
    }

    /// 按开关状态预约或取消后台任务
    func schedule() {
        let enabled = UserDefaults.standard.bool(forKey: "backgroundRefresh.enabled")
        if !enabled {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
            return
        }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(_ task: BGAppRefreshTask?) {
        guard let task else { return }
        schedule() // 预约下一次
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        Task {
            do {
                let service = VehicleServiceFactory.current()
                var snapshot = try await service.refresh()
                snapshot.carName = UserDefaults.standard.string(forKey: AppConstants.carNameKey) ?? snapshot.carName
                SharedStore.save(snapshot)
                if #available(iOS 16.2, *) {
                    LiveActivityManager.update(
                        with: snapshot,
                        enabled: UserDefaults.standard.bool(forKey: "liveActivity.enabled")
                    )
                }
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}

/// 启动时注册后台任务
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BackgroundRefreshManager.shared.registerAndSchedule()
        return true
    }
}
