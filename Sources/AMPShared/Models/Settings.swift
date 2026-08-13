import Foundation

public struct AppSettings: Codable {
    public var sprintMinutes: Int
    public var syncMinutes: Int
    public var resetMinutes: Int
    public var restMinutes: Int
    public var restAfterCycles: Int
    public var notificationsEnabled: Bool
    public var trackingEnabled: Bool
    public var floatingTimerEnabled: Bool

    public init(sprintMinutes: Int = 42,
         syncMinutes: Int = 9,
         resetMinutes: Int = 9,
         restMinutes: Int = 180,
         restAfterCycles: Int = 3,
         notificationsEnabled: Bool = true,
         trackingEnabled: Bool = true,
         floatingTimerEnabled: Bool = true) {
        self.sprintMinutes = sprintMinutes
        self.syncMinutes = syncMinutes
        self.resetMinutes = resetMinutes
        self.restMinutes = restMinutes
        self.restAfterCycles = restAfterCycles
        self.notificationsEnabled = notificationsEnabled
        self.trackingEnabled = trackingEnabled
        self.floatingTimerEnabled = floatingTimerEnabled
    }
}
