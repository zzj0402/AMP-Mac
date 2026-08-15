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
    @Published var focusColor: FocusColor {
        didSet { save() }
    }

    private let db = Database.shared
    private var cancellables = Set<AnyCancellable>()
    private var isReloading = false

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
        _focusColor = .init(wrappedValue: s.focusColor)

        NotificationCenter.default.publisher(for: .databaseDidChange)
            .sink { [weak self] _ in self?.reloadFromDatabase() }
            .store(in: &cancellables)
    }

    private func reloadFromDatabase() {
        guard !isReloading else { return }
        isReloading = true
        defer { isReloading = false }

        let s = db.getSettings()
        sprintMinutes = s.sprintMinutes
        syncMinutes = s.syncMinutes
        resetMinutes = s.resetMinutes
        restMinutes = s.restMinutes
        restAfterCycles = s.restAfterCycles
        notificationsEnabled = s.notificationsEnabled
        trackingEnabled = s.trackingEnabled
        floatingTimerEnabled = s.floatingTimerEnabled
        focusColor = s.focusColor
    }

    private func save() {
        guard !isReloading else { return }
        db.updateSettings(AppSettings(
            sprintMinutes: sprintMinutes,
            syncMinutes: syncMinutes,
            resetMinutes: resetMinutes,
            restMinutes: restMinutes,
            restAfterCycles: restAfterCycles,
            notificationsEnabled: notificationsEnabled,
            trackingEnabled: trackingEnabled,
            floatingTimerEnabled: floatingTimerEnabled,
            focusColor: focusColor
        ))
    }
}
