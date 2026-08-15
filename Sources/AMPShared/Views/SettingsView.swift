import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var timer: TimerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(7)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                DurationRow(title: "Sprint", systemImage: "bolt.fill", color: .blue, range: 1...90, unit: " min", value: $settingsStore.sprintMinutes, accessibilityID: "sprintStepper")
                DurationRow(title: "Logging", systemImage: "pencil.line", color: .orange, range: 0...30, unit: " min", value: $settingsStore.syncMinutes)
                DurationRow(title: "Break", systemImage: "cup.and.saucer.fill", color: .purple, range: 0...30, unit: " min", value: $settingsStore.resetMinutes)
                DurationRow(title: "Rest", systemImage: "moon.zzz.fill", color: .green, range: 0...240, unit: " min", value: $settingsStore.restMinutes)
                DurationRow(title: "Rest after cycles", systemImage: "arrow.triangle.2.circlepath", color: .teal, range: 1...8, unit: "", value: $settingsStore.restAfterCycles)
            } header: {
                Text("Durations (minutes)")
            } footer: {
                Text("Rest automatically follows every \(settingsStore.restAfterCycles) sprints.")
            }

            Section {
                Picker("Focus color", selection: $settingsStore.focusColor) {
                    ForEach(FocusColor.allCases, id: \.self) { color in
                        Label {
                            Text(color.displayName)
                        } icon: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            } header: {
                Text("Focus color")
            } footer: {
                Text("Sets the color of the countdown ring and the focus phase indicator.")
            }

            Section {
                Toggle(isOn: $settingsStore.notificationsEnabled) {
                    Text("Phase-change notifications")
                }
                #if canImport(AppKit)
                Toggle(isOn: $settingsStore.trackingEnabled) {
                    Text("Window tracking")
                }
                #endif
                Toggle(isOn: $settingsStore.floatingTimerEnabled) {
                    Text("Floating timer overlay")
                }
            } header: {
                Text("Options")
            } footer: {
                Text("Notifications play the AMP jingle and request attention when a phase changes. The floating timer overlay pins a live countdown to the screen edge.")
            }

            Section {
                Button {
                    timer.stop()
                } label: {
                    Label("Reset Timer", systemImage: "stop.fill")
                }
                .keyboardShortcut("r", modifiers: [.command])
            } header: {
                Text("Controls")
            } footer: {
                Text("Stops any running timer and returns to the idle state.")
            }
        }
        .formStyle(.grouped)
    }
}

private struct DurationRow: View {
    let title: String
    let systemImage: String
    let color: Color
    let range: ClosedRange<Int>
    let unit: String
    @Binding var value: Int
    var accessibilityID: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(title)
            Spacer()
            Text("\(value)\(unit)")
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 48, alignment: .trailing)
            Stepper(value: $value, in: range, label: { Text("") })
                .labelsHidden()
                .accessibilityIdentifier(accessibilityID ?? "")
        }
        .padding(.vertical, 2)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsStore())
            .environmentObject(TimerManager())
    }
}
