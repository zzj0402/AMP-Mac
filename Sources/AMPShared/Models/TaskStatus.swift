import Foundation

public enum TaskStatus: String, Codable {
    case pending
    case inProgress = "in_progress"
    case done
}

public enum TaskPriority: String, Codable {
    case low
    case medium
    case high
}
