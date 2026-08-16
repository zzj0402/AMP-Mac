import SwiftUI

#if os(iOS)
import UIKit

// MARK: - Screen geometry

/// Best-effort description of the surface the app is drawing into, so the edge
/// rail hugs the bezel instead of cutting across the rounded corners.
@MainActor
enum EdgeScreenGeometry {
    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    /// Approximate corner radius of the current display / window.
    ///
    /// UIKit does not expose the display corner radius publicly, so this leans
    /// on the home-indicator inset: devices with a bottom safe-area inset are
    /// the rounded-corner generation. iPads use a tighter radius than iPhones.
    static var cornerRadius: CGFloat {
        guard let window = keyWindow else { return 0 }
        guard window.safeAreaInsets.bottom > 0 else { return 0 }

        // In Split View / Stage Manager the app owns a window rather than the
        // whole screen, and that window has a smaller system corner radius.
        let isFullScreen: Bool
        if let screenSize = window.windowScene?.screen.bounds.size {
            isFullScreen = window.bounds.size == screenSize
                || window.bounds.size == CGSize(width: screenSize.height,
                                                height: screenSize.width)
        } else {
            isFullScreen = true
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            return isFullScreen ? 18 : 12
        }
        return isFullScreen ? 48 : 24
    }
}

// MARK: - Rail geometry

/// One half of the screen perimeter, drawn from the top centre, down one side,
/// to the bottom centre.
///
/// Two mirrored arms make the countdown read symmetrically: both retract toward
/// the top of the screen as the phase drains, so the remaining time is legible
/// from either edge without hunting for a start point.
struct EdgeRailArm: InsettableShape {
    enum Side {
        case leading
        case trailing
    }

    var side: Side
    var cornerRadius: CGFloat
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> EdgeRailArm {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let radius = max(0, min(cornerRadius - insetAmount, min(rect.width, rect.height) / 2))
        let outerX = side == .trailing ? rect.maxX : rect.minX
        let topMid = CGPoint(x: rect.midX, y: rect.minY)
        let bottomMid = CGPoint(x: rect.midX, y: rect.maxY)

        var path = Path()
        path.move(to: topMid)
        path.addArc(
            tangent1End: CGPoint(x: outerX, y: rect.minY),
            tangent2End: CGPoint(x: outerX, y: rect.maxY),
            radius: radius
        )
        path.addArc(
            tangent1End: CGPoint(x: outerX, y: rect.maxY),
            tangent2End: bottomMid,
            radius: radius
        )
        path.addLine(to: bottomMid)
        return path
    }
}

// MARK: - Edge rail

/// The screen-edge countdown measure for iPhone and iPad.
///
/// This is the iOS counterpart to the macOS `FloatingTimerWindow`, which pins
/// four borderless panels to the edges of the display. iOS apps cannot draw
/// outside their own window, so the four macOS panels are unified into a single
/// perimeter rail that drains as the phase counts down.
struct EdgeCountdownRail: View {
    @EnvironmentObject var timer: TimerManager

    /// Thickness of the drained rail.
    private let railWidth: CGFloat = 5
    /// Thickness of the soft bloom behind it, echoing the macOS side strips.
    private let bloomWidth: CGFloat = 16

    private var phaseColor: Color { timer.phase.color }

    /// Fraction of the phase still to run: 1 at the start, 0 at the buzzer.
    private var remaining: Double {
        1 - min(max(timer.progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let radius = EdgeScreenGeometry.cornerRadius
            ZStack {
                bloom(radius: radius)

                // Unspent track: the full perimeter, barely there.
                arm(.leading, radius: radius, to: 1, color: .white.opacity(0.16), width: railWidth)
                arm(.trailing, radius: radius, to: 1, color: .white.opacity(0.16), width: railWidth)

                // Remaining time, retracting toward the top of the screen.
                ZStack {
                    arm(.leading, radius: radius, to: remaining, color: phaseColor, width: railWidth)
                    arm(.trailing, radius: radius, to: remaining, color: phaseColor, width: railWidth)
                }
                .shadow(color: phaseColor.opacity(0.55), radius: 7)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(timer.isActive ? 1 : 0.45)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(.linear(duration: 1), value: timer.timeRemaining)
        .animation(.easeInOut(duration: 0.35), value: timer.phase)
        .animation(.easeInOut(duration: 0.25), value: timer.isActive)
    }

    private func arm(_ side: EdgeRailArm.Side,
                     radius: CGFloat,
                     to end: Double,
                     color: Color,
                     width: CGFloat) -> some View {
        EdgeRailArm(side: side, cornerRadius: radius)
            .inset(by: width / 2)
            .trim(from: 0, to: min(max(end, 0), 1))
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// Soft phase-tinted wash hugging the perimeter — the iOS stand-in for the
    /// solid colour strips macOS parks down the left and right of the screen.
    private func bloom(radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(phaseColor.opacity(0.30), lineWidth: bloomWidth)
            .blur(radius: 12)
    }
}

// MARK: - Edge readout

/// Compact phase + time readout pinned to the top edge, mirroring the macOS
/// top bar panel (`EdgeTopBar`). Sits inside the safe area so it clears the
/// notch, Dynamic Island and status bar.
struct EdgeTimerReadout: View {
    @EnvironmentObject var timer: TimerManager

    private var phaseColor: Color { timer.phase.color }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)
            Text(timer.phaseTitle)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            Text(timer.formattedTime)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().strokeBorder(phaseColor.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
        .opacity(timer.isActive ? 1 : 0.7)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timer.phaseTitle), \(timer.formattedTime) remaining")
        .animation(.easeInOut(duration: 0.35), value: timer.phase)
        .animation(.easeInOut(duration: 0.25), value: timer.isActive)
    }
}
#endif
