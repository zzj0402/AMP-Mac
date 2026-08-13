import AppKit
import Combine
import SwiftUI
import AMPShared

@MainActor
final class FloatingTimerWindow {
    static let shared = FloatingTimerWindow()

    private var panels: [NSPanel] = []
    private weak var timer: TimerManager?
    private var cancellables = Set<AnyCancellable>()
    private var enabled = true

    private let barThickness: CGFloat = 28
    private let stripThickness: CGFloat = 10

    private init() {}

    func attach(timer: TimerManager) {
        self.timer = timer
        cancellables = Set<AnyCancellable>()
        timer.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.syncVisibility() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .databaseDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.reloadEnabled() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.reposition() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.teardown() }
            .store(in: &cancellables)
        reloadEnabled()
        syncVisibility()
    }

    private func reloadEnabled() {
        enabled = Database.shared.getSettings().floatingTimerEnabled
        syncVisibility()
    }

    private func syncVisibility() {
        guard let timer else { return }
        if enabled && timer.isActive && timer.phase != .idle {
            show()
        } else {
            hide()
        }
    }

    private func show() {
        ensurePanels()
        guard !panels.isEmpty else { return }
        reposition()
        panels.forEach { $0.orderFrontRegardless() }
    }

    private func hide() {
        panels.forEach { $0.orderOut(nil) }
    }

    private func teardown() {
        hide()
        panels.forEach { $0.close() }
        panels.removeAll()
    }

    private func ensurePanels() {
        guard panels.isEmpty, let timer else { return }
        panels = [
            makePanel(EdgeTopBar(), timer: timer),
            makePanel(EdgeBottomBar(), timer: timer),
            makePanel(EdgeSideStrip(), timer: timer),
            makePanel(EdgeSideStrip(), timer: timer)
        ]
    }

    private func makePanel<Content: View>(_ content: Content, timer: TimerManager) -> NSPanel {
        let hosting = NSHostingView(rootView: content.environmentObject(timer))
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.contentView = hosting
        return panel
    }

    private func reposition() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first, panels.count >= 4 else { return }
        let frame = screen.visibleFrame
        panels[0].setFrame(
            NSRect(x: frame.minX, y: frame.maxY - barThickness, width: frame.width, height: barThickness),
            display: false
        )
        panels[1].setFrame(
            NSRect(x: frame.minX, y: frame.minY, width: frame.width, height: barThickness),
            display: false
        )
        panels[2].setFrame(
            NSRect(x: frame.minX, y: frame.minY, width: stripThickness, height: frame.height),
            display: false
        )
        panels[3].setFrame(
            NSRect(x: frame.maxX - stripThickness, y: frame.minY, width: stripThickness, height: frame.height),
            display: false
        )
    }
}

private struct EdgeTopBar: View {
    @EnvironmentObject var timer: TimerManager

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(timer.phaseColor)
                .frame(width: 8, height: 8)
            Text(timer.phaseTitle)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            Text(timer.formattedTime)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.75), radius: 2, x: 0, y: 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EdgeBottomBar: View {
    @EnvironmentObject var timer: TimerManager

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.25))
                    .frame(height: 4)
                Capsule()
                    .fill(timer.phaseColor)
                    .frame(width: geo.size.width * min(max(timer.progress, 0), 1), height: 4)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

private struct EdgeSideStrip: View {
    @EnvironmentObject var timer: TimerManager

    var body: some View {
        Rectangle()
            .fill(timer.phaseColor.opacity(0.7))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
