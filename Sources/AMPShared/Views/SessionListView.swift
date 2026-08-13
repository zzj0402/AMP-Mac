import SwiftUI

struct SessionListView: View {
    @EnvironmentObject var taskStore: TaskStore

    @State private var sessions: [Session] = []
    private let db = Database.shared

    var body: some View {
        VStack(spacing: 0) {
            header

            if sessions.isEmpty {
                EmptyStateView(
                    systemImage: "clock.arrow.circlepath",
                    title: "No sessions yet",
                    message: "Complete a sprint and your history will appear here."
                )
                .frame(maxHeight: .infinity)
            } else {
                List(sessions) { session in
                    SessionRow(session: session, title: taskTitle(session.taskId))
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange)) { _ in
            refresh()
        }
    }

    private var header: some View {
        HStack {
            Text("Sessions")
                .font(.title3.weight(.bold))
            Spacer()
            Label("\(Int(taskStore.totalFocusMinutes)) min focused", systemImage: "flame.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.6), in: Capsule())
            Button(action: refresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private func refresh() {
        sessions = db.getSessions(limit: 20)
    }

    private func taskTitle(_ id: Int) -> String {
        db.getTask(taskId: id)?.title ?? "Task \(id)"
    }
}

private struct SessionRow: View {
    let session: Session
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            PhaseBadge(phase: session.phase)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .lineLimit(1)
                Text(AppDate.medium(session.startedAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(session.plannedMinutes)) min")
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                HStack(spacing: 4) {
                    Image(systemName: session.completed ? "checkmark.seal.fill" : "seal.fill")
                        .font(.caption2)
                        .foregroundStyle(session.completed ? Color.green : Color.orange)
                    Text(session.completed ? "Completed" : "Skipped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionListView_Previews: PreviewProvider {
    static var previews: some View {
        SessionListView()
            .environmentObject(TaskStore())
    }
}
