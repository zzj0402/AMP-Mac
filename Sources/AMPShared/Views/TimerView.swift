import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timer: TimerManager
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var taskPendingRemoval: Task?

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    private var adaptivePadding: CGFloat {
        isCompactWidth ? 16 : 20
    }


    private var cardMaxWidth: CGFloat {
        isCompactWidth ? .infinity : 480
    }

    private var cardBackgroundColor: Color {
        #if canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(white: 0.97)
        #endif
    }

    private let ringSize: CGFloat = 236

    var body: some View {
        VStack(spacing: 16) {
            heroCard
            if timer.phase == .idle {
                taskPicker
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if timer.phase == .sync {
                logPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(adaptivePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: timer.phase)
    }

    private var phaseColor: Color { timer.phase.color }

    private var heroCard: some View {
        VStack(spacing: 22) {
            PhaseBadge(phase: timer.phase)
                .id(timer.phase)
                .transition(.scale(scale: 0.85).combined(with: .opacity))

            timerRing

            cycleInfo

            controls
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 24)
        .frame(maxWidth: cardMaxWidth)
        .background(cardBackground)
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(cardBackgroundColor)
            .overlay {
                ZStack {
                    Circle()
                        .fill(phaseColor.opacity(0.14))
                        .frame(width: ringSize + 80, height: ringSize + 80)
                        .blur(radius: 44)
                        .offset(y: -34)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(phaseColor.opacity(0.15), lineWidth: 16)
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [phaseColor, phaseColor.opacity(0.6), phaseColor]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timer.progress)
                .animation(.easeInOut(duration: 0.5), value: timer.phase)

            ringCenter
        }
        .frame(width: ringSize, height: ringSize)
    }

    private var ringCenter: some View {
        VStack(spacing: 6) {
            Text(timer.formattedTime)
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(phasePrompt)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal, 12)
        }
        .id(timer.phase)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private var phasePrompt: String {
        switch timer.phase {
        case .idle: return "Ready when you are"
        case .sprint: return timer.currentTask?.title ?? "Focus on your task"
        case .sync: return "Log what you accomplished"
        case .reset: return "Stand up, stretch, breathe"
        case .rest: return "Long break — recharge"
        }
    }

    @ViewBuilder
    private var cycleInfo: some View {
        if timer.phase == .sprint && settingsStore.restAfterCycles > 0 {
            let current = (timer.cyclesCompleted % settingsStore.restAfterCycles) + 1
            Text("Sprint \(current) of \(settingsStore.restAfterCycles)")
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(phaseColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(phaseColor.opacity(0.12), in: Capsule())
        } else if timer.phase != .idle && timer.cyclesCompleted > 0 {
            Text(timer.cyclesCompleted == 1 ? "1 sprint completed" : "\(timer.cyclesCompleted) sprints completed")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch (timer.phase, timer.isActive) {
        case (.idle, _):
            HStack(spacing: 12) {
                ControlButton(title: "Start", systemImage: "play.fill", prominent: true) {
                    timer.start(task: timer.currentTask)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(timer.currentTask == nil)
                .help(timer.currentTask == nil ? "Select a task to start" : "Start the timer")

                ControlButton(title: "New Task", systemImage: "plus") {
                    timer.showingAddTask = true
                }
            }
        case (_, true):
            HStack(spacing: 12) {
                ControlButton(title: "Pause", systemImage: "pause.fill", prominent: true) {
                    timer.pause()
                }
                ControlButton(title: "Stop", systemImage: "stop.fill") {
                    timer.stop()
                }
                ControlButton(title: "Skip", systemImage: "forward.end.fill") {
                    timer.skip()
                }
            }
        default:
            HStack(spacing: 12) {
                ControlButton(title: "Resume", systemImage: "play.fill", prominent: true) {
                    timer.resume()
                }
                .keyboardShortcut(.defaultAction)
                ControlButton(title: "Stop", systemImage: "stop.fill") {
                    timer.stop()
                }
            }
        }
    }

    // MARK: - Log phase

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: Phase.sync.icon)
                    .foregroundStyle(Phase.sync.color)
                Text("Log your work")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(taskStore.pending.count) open")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary.opacity(0.6), in: Capsule())
            }

            if logTasks.isEmpty {
                Text("Nothing left to log — every task is complete.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(logTasks) { task in
                            LogTaskRow(
                                task: task,
                                isCurrent: task.id == timer.currentTask?.id,
                                onComplete: { complete(task) },
                                onReopen: { taskStore.reopen(task) },
                                onRemove: { taskPendingRemoval = task }
                            )
                        }
                    }
                }
                .frame(maxHeight: 168)
            }

            if !recentlyCompleted.isEmpty {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(recentlyCompleted.count == 1
                         ? "1 task completed"
                         : "\(recentlyCompleted.count) tasks completed")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let last = recentlyCompleted.first {
                        Button("Undo") { taskStore.reopen(last) }
                            .buttonStyle(.borderless)
                            .font(.caption.weight(.semibold))
                            .help("Reopen \"\(last.title)\"")
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: cardMaxWidth)
        .background(cardBackgroundColor.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .confirmationDialog(
            taskPendingRemoval.map { "Remove \"\($0.title)\"?" } ?? "Remove task?",
            isPresented: removalConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Remove Task", role: .destructive) {
                if let task = taskPendingRemoval { remove(task) }
                taskPendingRemoval = nil
            }
            Button("Cancel", role: .cancel) { taskPendingRemoval = nil }
        } message: {
            Text("This deletes the task and its recorded sessions. This cannot be undone.")
        }
    }

    /// Open tasks, with the current focus task pinned to the top so it is the
    /// first thing you can log against.
    private var logTasks: [Task] {
        let open = taskStore.pending
        guard let currentId = timer.currentTask?.id,
              let index = open.firstIndex(where: { $0.id == currentId }) else { return open }
        var ordered = open
        let current = ordered.remove(at: index)
        ordered.insert(current, at: 0)
        return ordered
    }

    /// Tasks completed today, newest first, so the log summary reflects this
    /// session's work rather than all-time completions.
    private var recentlyCompleted: [Task] {
        taskStore.completed
            .filter { AppDate.isToday($0.completedAt) }
            .sorted { ($0.completedAt ?? "") > ($1.completedAt ?? "") }
    }

    private var removalConfirmationPresented: Binding<Bool> {
        Binding(
            get: { taskPendingRemoval != nil },
            set: { if !$0 { taskPendingRemoval = nil } }
        )
    }

    private func complete(_ task: Task) {
        let wasCurrent = task.id == timer.currentTask?.id
        taskStore.complete(task)
        if wasCurrent {
            timer.currentTask = taskStore.nextPending(excluding: task)
        }
    }

    private func remove(_ task: Task) {
        let wasCurrent = task.id == timer.currentTask?.id
        taskStore.delete(task)
        if wasCurrent {
            timer.currentTask = taskStore.nextPending(excluding: task)
        }
    }

    private var taskPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .foregroundStyle(.blue)
                Text("Focus task")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            Picker("Focus task", selection: taskSelection) {
                Text("No task selected").tag(nil as Int?)
                ForEach(taskStore.pending) { task in
                    Text(task.title).tag(task.id as Int?)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .disabled(taskStore.pending.isEmpty)

            if taskStore.pending.isEmpty {
                Text("Add a task to begin your first sprint.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(cardBackgroundColor.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var taskSelection: Binding<Int?> {
        Binding(
            get: { timer.currentTask?.id },
            set: { id in
                if let id {
                    timer.currentTask = taskStore.tasks.first(where: { $0.id == id })
                } else {
                    timer.currentTask = nil
                }
            }
        )
    }
}

/// One open task in the log phase, with inline complete and remove actions.
private struct LogTaskRow: View {
    let task: Task
    let isCurrent: Bool
    let onComplete: () -> Void
    let onReopen: () -> Void
    let onRemove: () -> Void

    private var isDone: Bool { task.status == .done }

    private var hitSize: CGFloat {
        #if os(iOS)
        return 44
        #else
        return 26
        #endif
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: isDone ? onReopen : onComplete) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                    .frame(width: hitSize, height: hitSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isDone ? "Reopen this task" : "Mark this task complete")
            .accessibilityLabel(isDone ? "Reopen \(task.title)" : "Complete \(task.title)")

            Text(task.title)
                .font(.callout)
                .strikethrough(isDone)
                .foregroundStyle(isDone ? Color.secondary : Color.primary)
                .lineLimit(1)

            if isCurrent {
                Image(systemName: "target")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .help("Current focus task")
            }

            Spacer(minLength: 8)

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: hitSize, height: hitSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Remove this task")
            .accessibilityLabel("Remove \(task.title)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isCurrent ? Color.blue.opacity(0.08) : Color.clear)
        )
        .contextMenu {
            if isDone {
                Button {
                    onReopen()
                } label: {
                    Label("Reopen Task", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button {
                    onComplete()
                } label: {
                    Label("Complete Task", systemImage: "checkmark.circle")
                }
            }
            Divider()
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove Task", systemImage: "trash")
            }
        }
    }
}

private struct ControlButton: View {
    let title: String
    let systemImage: String
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Group {
            if prominent {
                Button(action: action) { content }
                    .buttonStyle(.borderedProminent)
            } else {
                Button(action: action) { content }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var content: some View {
        Label(title, systemImage: systemImage)
            .font(.body.weight(.semibold))
            .frame(minWidth: 88)
            .padding(.vertical, 4)
            #if os(iOS)
            .frame(minHeight: 44)
            #endif
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
            .environmentObject(TimerManager())
            .environmentObject(SettingsStore())
            .environmentObject(TaskStore())
    }
}
