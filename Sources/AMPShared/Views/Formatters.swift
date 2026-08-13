import Foundation

enum AppDate {
    private static let iso = ISO8601DateFormatter()

    private static func parse(_ value: String) -> Date? {
        iso.date(from: value)
    }

    static func short(_ value: String) -> String {
        guard let date = parse(value) else { return value }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    static func medium(_ value: String) -> String {
        guard let date = parse(value) else { return value }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy · h:mm a"
        return formatter.string(from: date)
    }
}
