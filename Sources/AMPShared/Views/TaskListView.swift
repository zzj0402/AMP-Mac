import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var timer: TimerManager

    @State private var showingAdd = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if taskStore.tasks.isEmpty {
                EmptyStateView(
                    systemImage: "checklist",
                    title: "No tasks yet",
                    message: "Add a task to start tracking your focus."
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(taskStore.tasks) { task in
                        TaskRow(task: task, isCurrent: task.id == timer.currentTask?.id) {
                            taskStore.toggleDone(task)
                        }
                        .onTapGesture { timer.currentTask = task }
                        .contextMenu {
                            Button {
                                timer.currentTask = task
                            } label: {
                                Label("Set as Focus Task", systemImage: "target")
                            }
                            Divider()
                            Button {
                                if let index = taskStore.tasks.firstIndex(where: { $0.id == task.id }) {
                                    taskStore.delete(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: taskStore.delete)
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }

            Divider()

            HStack {
                Spacer()
                Button {
                    showingAdd = true
                } label: {
                    Label("Add Task", systemImage: "plus")
                        #if os(iOS)
                        .padding(.vertical, 8)
                        #endif
                }
                .keyboardShortcut("n", modifiers: [.command])
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .sheet(isPresented: $showingAdd) {
            AddTaskSheet()
        }
    }

    private var header: some View {
        HStack {
            Text("Tasks")
                .font(.title3.weight(.bold))
            Spacer()
            Text("\(taskStore.pending.count) open")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.6), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

private struct TaskRow: View {
    let task: Task
    let isCurrent: Bool
    let onToggle: () -> Void

    private var iconSize: CGFloat {
        #if os(iOS)
        return 44
        #else
        return 26
        #endif
    }

    private var rowPadding: CGFloat {
        #if os(iOS)
        return 10
        #else
        return 4
        #endif
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: statusIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: iconSize, height: iconSize)
                    .background(statusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(task.status == .done ? "Mark as not done" : "Mark as done")

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.status == .done)
                    .foregroundStyle(task.status == .done ? Color.secondary : Color.primary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    priorityBadge
                    Text(AppDate.short(task.createdAt))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if isCurrent {
                Label("Focusing", systemImage: "target")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, rowPadding)
        .contentShape(Rectangle())
    }

    private var statusIcon: String {
        switch task.status {
        case .done: return "checkmark"
        case .inProgress: return "clock.fill"
        case .pending: return "circle"
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .done: return .green
        case .inProgress: return .blue
        case .pending: return .secondary
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 6, height: 6)
            Text(task.priority.rawValue.capitalized)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(priorityColor(task.priority).opacity(0.12), in: Capsule())
        .foregroundStyle(priorityColor(task.priority))
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct AddTaskSheet: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var timer: TimerManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var priority: TaskPriority = .medium

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("New Task")
                    .font(.title2.weight(.bold))
                Spacer()
                Button {
                    timer.showingAddTask = false
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Task name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("What are you focusing on?", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(add)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Priority")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Priority", selection: $priority) {
                    Text("Low").tag(TaskPriority.low)
                    Text("Medium").tag(TaskPriority.medium)
                    Text("High").tag(TaskPriority.high)
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    timer.showingAddTask = false
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Add") { add() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private func add() {
        taskStore.add(title: title.trimmingCharacters(in: .whitespaces), priority: priority)
        timer.showingAddTask = false
        dismiss()
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .environmentObject(TaskStore())
            .environmentObject(TimerManager())
    }
}
