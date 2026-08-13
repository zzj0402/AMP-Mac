import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timer: TimerManager
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var taskStore: TaskStore

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
            }
        }
        .padding(20)
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
        .frame(maxWidth: 480)
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
