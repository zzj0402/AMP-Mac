import Foundation
import Combine

extension Notification.Name {
    public static let databaseDidChange = Notification.Name("AMPDatabaseDidChange")
}

final class SettingsStore: ObservableObject {
    @Published var sprintMinutes: Int {
        didSet { save() }
    }
    @Published var syncMinutes: Int {
        didSet { save() }
    }
    @Published var resetMinutes: Int {
        didSet { save() }
    }
    @Published var restMinutes: Int {
        didSet { save() }
    }
    @Published var restAfterCycles: Int {
        didSet { save() }
    }
    @Published var notificationsEnabled: Bool {
        didSet { save() }
    }
    @Published var trackingEnabled: Bool {
        didSet { save() }
    }
    @Published var floatingTimerEnabled: Bool {
        didSet { save() }
    }

    private let db = Database.shared

    init() {
        let s = db.getSettings()
        _sprintMinutes = .init(wrappedValue: s.sprintMinutes)
        _syncMinutes = .init(wrappedValue: s.syncMinutes)
        _resetMinutes = .init(wrappedValue: s.resetMinutes)
        _restMinutes = .init(wrappedValue: s.restMinutes)
        _restAfterCycles = .init(wrappedValue: s.restAfterCycles)
        _notificationsEnabled = .init(wrappedValue: s.notificationsEnabled)
        _trackingEnabled = .init(wrappedValue: s.trackingEnabled)
        _floatingTimerEnabled = .init(wrappedValue: s.floatingTimerEnabled)
    }

    private func save() {
        db.updateSettings(AppSettings(
            sprintMinutes: sprintMinutes,
            syncMinutes: syncMinutes,
            resetMinutes: resetMinutes,
            restMinutes: restMinutes,
            restAfterCycles: restAfterCycles,
            notificationsEnabled: notificationsEnabled,
            trackingEnabled: trackingEnabled,
            floatingTimerEnabled: floatingTimerEnabled
        ))
    }
}
