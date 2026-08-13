import SwiftUI

#if os(iOS)
struct FloatingTimerOverlayView: View {
    @EnvironmentObject var timer: TimerManager
    @EnvironmentObject var settingsStore: SettingsStore

    private var visible: Bool {
        settingsStore.floatingTimerEnabled && timer.isActive && timer.phase != .idle
    }

    var body: some View {
        if visible {
            HStack(spacing: 8) {
                Circle()
                    .fill(timer.phase.color)
                    .frame(width: 8, height: 8)
                Text(timer.phaseTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(timer.formattedTime)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: timer.isActive)
            .animation(.easeInOut(duration: 0.3), value: timer.phase)
        }
    }
}
#endif
