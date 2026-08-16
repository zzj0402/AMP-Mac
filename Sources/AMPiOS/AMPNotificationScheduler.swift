import Foundation
import UserNotifications
import AMPShared

#if os(iOS)
enum AMPNotificationScheduler {
    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge]) { _, _ in }
    }

    static func schedule(phase: Phase, title: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body(for: phase)
        let request = UNNotificationRequest(
            identifier: "amp.phase.\(phase.rawValue)",
            content: content,
            trigger: nil
        )
        ensureAuthorized { granted in
            guard granted else { return }
            UNUserNotificationCenter.current().add(request)
        }
    }

    static func ensureAuthorized(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
            case .notDetermined:
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge]) { granted, _ in
                        completion(granted)
                    }
            default:
                completion(false)
            }
        }
    }

    static func body(for phase: Phase) -> String {
        switch phase {
        case .sprint: return "Focus time — get in the zone."
        case .sync: return "Time to log what you accomplished."
        case .reset: return "Short break — stretch it out."
        case .rest: return "Long rest — recharge before the next cycle."
        case .idle: return "Timer is idle."
        }
    }
}
#endif
