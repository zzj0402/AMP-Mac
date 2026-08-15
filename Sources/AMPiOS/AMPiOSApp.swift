import SwiftUI
import AMPShared

#if os(iOS)
import UserNotifications
#endif

@main
struct AMPiOSApp: App {
    init() {
        #if os(iOS)
        PlatformBridge.registerFloatingTimer { _ in }
        PlatformBridge.registerAttention {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        PlatformBridge.registerPhaseNotification { phase, title in
            AMPNotificationScheduler.schedule(phase: phase, title: title)
        }
        AMPNotificationScheduler.requestPermission()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
