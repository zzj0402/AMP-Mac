import Foundation

public enum PlatformBridge {
    static var floatingTimerAttach: (@MainActor (TimerManager) -> Void)?
    static var requestAttention: (@MainActor () -> Void)?
    static var schedulePhaseNotification: (@MainActor (Phase, String) -> Void)?

    public static func registerFloatingTimer(_ handler: @escaping @MainActor (TimerManager) -> Void) {
        floatingTimerAttach = handler
    }

    public static func registerAttention(_ handler: @escaping @MainActor () -> Void) {
        requestAttention = handler
    }

    public static func registerPhaseNotification(_ handler: @escaping @MainActor (Phase, String) -> Void) {
        schedulePhaseNotification = handler
    }

    @MainActor
    public static func notifyPhaseChange(_ phase: Phase, title: String? = nil) {
        let title = title ?? phase.displayName
        schedulePhaseNotification?(phase, title)
    }
}
