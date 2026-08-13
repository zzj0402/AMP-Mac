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
        var updated = task
        updated.status = task.status == .done ? .pending : .done
        if updated.status == .done {
            updated.completedAt = ISO8601DateFormatter().string(from: Date())
        } else {
            updated.completedAt = nil
        }
        db.updateTask(updated)
    }

    func delete(at offsets: IndexSet) {
        offsets.map { tasks[$0].id }.compactMap { $0 }.forEach { db.deleteTask(taskId: $0) }
        reload()
    }

    var pending: [Task] { tasks.filter { $0.status != .done } }
    var completed: [Task] { tasks.filter { $0.status == .done } }
    var totalFocusMinutes: Int { Int(db.getTotalFocusMinutes()) }
}
