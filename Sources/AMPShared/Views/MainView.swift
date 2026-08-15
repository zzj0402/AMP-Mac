import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case focus
    case tasks
    case sessions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .tasks: return "Tasks"
        case .sessions: return "Sessions"
        }
    }

    var icon: String {
        switch self {
        case .focus: return "timer"
        case .tasks: return "checklist"
        case .sessions: return "clock.arrow.circlepath"
        }
    }
}

public struct MainView: View {
    @StateObject private var taskStore = TaskStore()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var timerManager = TimerManager()
    @State private var section: AppSection = .focus
    @State private var showSettings = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init() {}

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    private var adaptivePadding: CGFloat {
        isCompactWidth ? 16 : 20
    }

    public var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                header

                Divider()

                Picker("Section", selection: $section) {
                    ForEach(AppSection.allCases) { s in
                        Label(s.title, systemImage: s.icon).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, adaptivePadding)
                .padding(.top, 10)

                content
            }

            #if os(iOS)
            FloatingTimerOverlayView()
            #endif
        }
        .environmentObject(taskStore)
        .environmentObject(settingsStore)
        .environmentObject(timerManager)
        .onAppear {
            timerManager.currentTask = taskStore.tasks.first(where: { $0.status != .done })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(taskStore)
                .environmentObject(settingsStore)
                .environmentObject(timerManager)
                .frame(minWidth: 480, minHeight: 460)
        }
        .sheet(isPresented: $timerManager.showingAddTask) {
            AddTaskSheet()
                .environmentObject(taskStore)
                .environmentObject(settingsStore)
                .environmentObject(timerManager)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 20))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 1) {
                Text("AMP")
                    .font(.title2.weight(.bold))
                Text("Sprint · Log · Break · Rest")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Label("\(taskStore.totalFocusMinutes) min focused", systemImage: "flame.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.quaternary.opacity(0.6), in: Capsule())
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        #if os(iOS)
                        .padding(8)
                        #endif
                        .background(Circle().fill(.quaternary.opacity(0.6)))
                }
                .buttonStyle(.plain)
                .help("Settings")
                .accessibilityLabel("Open Settings")
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
        .padding(.horizontal, adaptivePadding)
        .padding(.vertical, 14)
    }

    private var content: some View {
        Group {
            switch section {
            case .focus:
                TimerView()
            case .tasks:
                TaskListView()
            case .sessions:
                SessionListView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(section)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: section)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
