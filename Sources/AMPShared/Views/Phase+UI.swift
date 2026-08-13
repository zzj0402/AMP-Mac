import SwiftUI

extension FocusColor {
    public var color: Color {
        switch self {
        case .blue: return .blue
        case .orange: return .orange
        case .purple: return .purple
        case .green: return .green
        case .red: return .red
        case .teal: return .teal
        case .pink: return .pink
        }
    }
}

extension Phase {
    var displayName: String {
        switch self {
        case .sprint: return "Sprint"
        case .sync: return "Logging"
        case .reset: return "Break"
        case .rest: return "Rest"
        case .idle: return "Idle"
        }
    }

    var icon: String {
        switch self {
        case .sprint: return "bolt.fill"
        case .sync: return "pencil.line"
        case .reset: return "cup.and.saucer.fill"
        case .rest: return "moon.zzz.fill"
        case .idle: return "timer"
        }
    }

    var color: Color {
        switch self {
        case .sprint: return Database.shared.getSettings().focusColor.color
        case .sync: return .orange
        case .reset: return .purple
        case .rest: return .green
        case .idle: return .secondary
        }
    }
}

struct PhaseBadge: View {
    let phase: Phase

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: phase.icon)
                .font(.caption.weight(.semibold))
            Text(phase.displayName)
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(phase.color)
        .background(phase.color.opacity(0.14), in: Capsule())
    }
}
