import Foundation
import Combine

final class TaskStore: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var selected: Task?

    private let db = Database.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        reload()
        NotificationCenter.default.publisher(for: .databaseDidChange)
            .sink { _ in self.reload() }
            .store(in: &cancellables)
    }

    func reload() {
        tasks = db.getTasks()
        if let selected, !tasks.contains(where: { $0.id == selected.id }) {
            self.selected = tasks.first
        }
    }

    func add(title: String, priority: TaskPriority = .medium) {
        let task = Task(title: title, priority: priority)
        _ = db.addTask(task)
        reload()
    }

    func toggleDone(_ task: Task) {
        setDone(task, done: task.status != .done)
    }

    /// Explicitly marks a task done or reopens it. Used by the log phase where the
    /// intent is always unambiguous rather than a toggle.
    func setDone(_ task: Task, done: Bool) {
        var updated = task
        updated.status = done ? .done : .pending
        updated.completedAt = done ? ISO8601DateFormatter().string(from: Date()) : nil
        db.updateTask(updated)
        reload()
    }

    func complete(_ task: Task) {
        setDone(task, done: true)
    }

    func reopen(_ task: Task) {
        setDone(task, done: false)
    }

    func delete(at offsets: IndexSet) {
        offsets.map { tasks[$0].id }.compactMap { $0 }.forEach { db.deleteTask(taskId: $0) }
        reload()
    }

    func delete(_ task: Task) {
        guard let id = task.id else { return }
        db.deleteTask(taskId: id)
        reload()
    }

    /// First open task that is not `excluding`, used to pick a replacement focus task.
    func nextPending(excluding excluded: Task? = nil) -> Task? {
        pending.first { $0.id != excluded?.id }
    }

    var pending: [Task] { tasks.filter { $0.status != .done } }
    var completed: [Task] { tasks.filter { $0.status == .done } }
    var totalFocusMinutes: Int { Int(db.getTotalFocusMinutes()) }
}
