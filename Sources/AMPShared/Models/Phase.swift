import Foundation

public enum Phase: String, CaseIterable, Codable {
    case sprint
    case sync
    case reset
    case rest
    case idle
}
