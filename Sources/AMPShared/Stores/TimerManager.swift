import Foundation
import Combine
import SwiftUI

@MainActor
public final class TimerManager: ObservableObject {
    @Published public private(set) var phase: Phase = .idle
    @Published public private(set) var timeRemaining: Int = 0
    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var cyclesCompleted: Int = 0

    @Published public var currentTask: Task?

    @Published public var showingAddTask = false

    private var timer: AnyCancellable?
    private let db = Database.shared
    private let soundPlayer = PhaseSoundPlayer.shared
    private var cancellables = Set<AnyCancellable>()

    private var settings: AppSettings { db.getSettings() }

    private func minutesForPhase(_ ph: Phase) -> Int {
        switch ph {
        case .sprint: settings.sprintMinutes
        case .sync: settings.syncMinutes
        case .reset: settings.resetMinutes
        case .rest: settings.restMinutes
        case .idle: 0
        }
    }

    public var progress: Double {
        let total = Double(minutesForPhase(phase)) * 60
        guard total > 0 else { return 0 }
        return (total - Double(timeRemaining)) / total
    }

    public var formattedTime: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    public var phaseTitle: String {
        switch phase {
        case .sprint:
            return currentTask?.title ?? "Sprint"
        case .sync: return "Logging"
        case .reset: return "Break"
        case .rest: return "Rest"
        case .idle: return "Idle"
        }
    }

    public var phaseColor: Color {
        phase.color
    }

    public init() {
        NotificationCenter.default.publisher(for: .databaseDidChange)
            .sink { _ in }
            .store(in: &cancellables)
        PlatformBridge.floatingTimerAttach?(self)
    }

    deinit {
        timer?.cancel()
    }

    // MARK: - Public Controls

    public func start(task: Task? = nil) {
        if let task { currentTask = task }
        guard phase == .idle, let task = currentTask else { return }
        startSession(phase: .sprint, planned: settings.sprintMinutes, task: task)
    }

    public func startManually(phase: Phase) {
        guard self.phase == .idle, phase != .idle else { return }
        let planned = minutesForPhase(phase)
        startSession(phase: phase, planned: planned, task: currentTask ?? Task(title: phaseTitle))
    }

    public func pause() {
        guard isActive else { return }
        isActive = false
        timer?.cancel()
    }

    public func resume() {
        guard !isActive, phase != .idle else { return }
        run()
    }

    public func stop() {
        isActive = false
        timer?.cancel()
        endIdle()
    }

    public func skip() {
        complete(activeSession, completed: false)
        advanceCycle()
    }

    // MARK: - Session Logic

    private var activeSession: Session?

    private func endIdle() {
        phase = .idle
        timeRemaining = 0
        currentTask = nil
        activeSession = nil
    }

    private func startSession(phase: Phase, planned: Int, task: Task) {
        self.phase = phase
        self.timeRemaining = planned * 60
        self.isActive = true

        activeSession = Session(
            taskId: task.id ?? 0,
            phase: phase,
            plannedMinutes: Double(planned),
            startedAt: ISO8601DateFormatter().string(from: Date()),
            completed: false
        )
        _ = db.addSession(activeSession!)

        run()
    }

    private func run() {
        isActive = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in self.tick() }
    }

    private func tick() {
        guard timeRemaining > 0 else { finish(); return }
        timeRemaining -= 1
    }

    private func finish() {
        complete(activeSession, completed: true)
        advanceCycle()
    }

    private func complete(_ session: Session?, completed: Bool) {
        guard var session else { return }
        session.completed = completed
        session.endedAt = ISO8601DateFormatter().string(from: Date())
        db.updateSession(session)
        activeSession = session
    }

    private func advanceCycle() {
        timer?.cancel()
        isActive = false

        let restLimit = settings.restAfterCycles

        switch phase {
        case .sprint:
            cyclesCompleted += 1
            if cyclesCompleted % restLimit == 0 {
                transition(to: .rest)
            } else {
                transition(to: .sync)
            }
        case .sync:
            transition(to: .reset)
        case .reset:
            transition(to: .sprint)
        case .rest:
            transition(to: .sprint)
        case .idle:
            endIdle()
        }
    }

    private func transition(to newPhase: Phase) {
        let planned = minutesForPhase(newPhase)
        phase = newPhase
        timeRemaining = planned * 60
        isActive = false

        let task = currentTask ?? Task(title: phaseTitleFor(newPhase))
        activeSession = Session(
            taskId: task.id ?? 0,
            phase: newPhase,
            plannedMinutes: Double(planned),
            startedAt: ISO8601DateFormatter().string(from: Date()),
            completed: false
        )
        _ = db.addSession(activeSession!)

        if settings.notificationsEnabled {
            soundPlayer.play()
            PlatformBridge.notifyPhaseChange(newPhase)
        }

        if newPhase == .sprint {
            requestUserAttention()
        }
    }

    private func phaseTitleFor(_ ph: Phase) -> String {
        switch ph {
        case .sprint: return "Sprint"
        case .sync: return "Logging"
        case .reset: return "Break"
        case .rest: return "Rest"
        case .idle: return "Idle"
        }
    }

    private func requestUserAttention() {
        PlatformBridge.requestAttention?()
    }

    func startSprintIfIdle() {
        guard phase == .idle else { return }
        if currentTask == nil {
            showingAddTask = true
            return
        }
        start(task: currentTask)
    }
}
extension Notification.Name {
    static let startAlert = Notification.Name("AMPStartAlert")
}
