import SwiftUI
import AMPShared

#if os(iOS)
import UIKit
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
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
