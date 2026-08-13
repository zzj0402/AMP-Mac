import Foundation

public struct Session: Identifiable, Codable {
    public var id: Int?
    public var taskId: Int
    public var phase: Phase
    public var plannedMinutes: Double
    public var startedAt: String
    public var completed: Bool
    public var endedAt: String?
    public var activeWindowLog: String?

    public init(id: Int? = nil,
         taskId: Int,
         phase: Phase,
         plannedMinutes: Double,
         startedAt: String = ISO8601DateFormatter().string(from: Date()),
         completed: Bool = false,
         endedAt: String? = nil,
         activeWindowLog: String? = nil) {
        self.id = id
        self.taskId = taskId
        self.phase = phase
        self.plannedMinutes = plannedMinutes
        self.startedAt = startedAt
        self.completed = completed
        self.endedAt = endedAt
        self.activeWindowLog = activeWindowLog
    }
}
