import Foundation

public enum PlatformBridge {
    static var floatingTimerAttach: (@MainActor (TimerManager) -> Void)?
    static var requestAttention: (@MainActor () -> Void)?

    public static func registerFloatingTimer(_ handler: @escaping @MainActor (TimerManager) -> Void) {
        floatingTimerAttach = handler
    }

    public static func registerAttention(_ handler: @escaping @MainActor () -> Void) {
        requestAttention = handler
    }
}
