import SwiftUI

#if os(iOS)
/// Screen-edge timer overlay for iPhone and iPad.
///
/// Matches the macOS floating timer (`FloatingTimerWindow`): while a phase is
/// running, the edges of the display carry the countdown — a phase-tinted rail
/// that drains around the perimeter, plus a compact readout on the top edge.
struct FloatingTimerOverlayView: View {
    @EnvironmentObject var timer: TimerManager
    @EnvironmentObject var settingsStore: SettingsStore

    /// Shown for any live phase, including a paused or just-transitioned one,
    /// which the rail dims rather than hides.
    private var visible: Bool {
        settingsStore.floatingTimerEnabled && timer.phase != .idle
    }

    var body: some View {
        ZStack(alignment: .top) {
            if visible {
                EdgeCountdownRail()
                EdgeTimerReadout()
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.3), value: visible)
    }
}
#endif
