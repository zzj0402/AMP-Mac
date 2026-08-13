import Foundation

public struct Task: Identifiable, Codable {
    public var id: Int?
    public var title: String
    public var status: TaskStatus
    public var priority: TaskPriority
    public var createdAt: String
    public var completedAt: String?

    public init(id: Int? = nil,
         title: String,
         status: TaskStatus = .pending,
         priority: TaskPriority = .medium,
         createdAt: String = ISO8601DateFormatter().string(from: Date()),
         completedAt: String? = nil) {
        self.id = id
        self.title = title
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}
