import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var pressedChoice: HapticChoice?
    @State private var previewedChoice: HapticChoice?
    @State private var previewTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Haptics") {
                Picker("Pulse Style", selection: $sessionManager.pulseStyle) {
                    ForEach(PulseStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                if sessionManager.pulseStyle == .steady {
                    Text("Haptic Type")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(HapticChoice.allCases) { choice in
                        hapticRow(
                            choice,
                            isSelected: sessionManager.steadyHapticChoice == choice,
                            selectionMode: .steady
                        )
                    }
                } else {
                    Text("Haptic Types")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(HapticChoice.allCases) { choice in
                        hapticRow(
                            choice,
                            isSelected: sessionManager.selectedHapticChoices.contains(choice),
                            selectionMode: .varied
                        )
                    }
                }

                Picker("Hits per Pulse", selection: $sessionManager.clicksPerPulse) {
                    ForEach(SessionManager.clicksPerPulseChoices, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }

                Picker("Pulse Spacing", selection: $sessionManager.pulseSpacingStyle) {
                    ForEach(PulseSpacingStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                if sessionManager.pulseSpacingStyle == .fixed {
                    Picker("Pulses per Minute", selection: $sessionManager.pulsesPerMinute) {
                        ForEach(SessionManager.pulsesPerMinuteChoices, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }

                    Text("More pulses per minute means a shorter gap between pulse trains.")
                } else {
                    Picker("Minimum Gap", selection: $sessionManager.minimumVariedGap) {
                        ForEach(Self.gapChoices, id: \.self) { gap in
                            Text(gap.formatted(.number.precision(.fractionLength(1))) + " sec")
                                .tag(gap)
                        }
                    }

                    Picker("Maximum Gap", selection: $sessionManager.maximumVariedGap) {
                        ForEach(Self.gapChoices, id: \.self) { gap in
                            Text(gap.formatted(.number.precision(.fractionLength(1))) + " sec")
                                .tag(gap)
                        }
                    }
                }

                Picker("Max Duration", selection: $sessionManager.maxDurationMinutes) {
                    Text("2 min").tag(2.0)
                    Text("5 min").tag(5.0)
                    Text("10 min").tag(10.0)
                    Text("15 min").tag(15.0)
                }
            }

            Section("Location") {
                Toggle("Coarse Location", isOn: $sessionManager.locationLoggingEnabled)
                    .onChange(of: sessionManager.locationLoggingEnabled) { _, isEnabled in
                        if isEnabled {
                            sessionManager.requestLocationPermission()
                        }
                    }
            }

            Section("History") {
                NavigationLink("Sessions") {
                    HistoryView()
                }

                Button("Delete All", role: .destructive) {
                    Task {
                        await sessionManager.deleteAllRecords()
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }

    private static let gapChoices = stride(
        from: HapticSettings.allowedGapRange.lowerBound,
        through: HapticSettings.allowedGapRange.upperBound,
        by: 0.5
    ).map { $0 }

    private enum HapticSelectionMode {
        case steady
        case varied
    }

    private func hapticRow(
        _ choice: HapticChoice,
        isSelected: Bool,
        selectionMode: HapticSelectionMode
    ) -> some View {
        HStack {
            Text(choice.displayName)
            Spacer()
            if previewedChoice == choice {
                Image(systemName: "waveform")
                    .foregroundStyle(StillRainPalette.accent)
            } else if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(StillRainPalette.accent)
            }
        }
        .contentShape(Rectangle())
        .opacity(pressedChoice == choice ? 0.6 : 1)
        .gesture(previewGesture(for: choice, selectionMode: selectionMode))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Hold to preview, then release to select")
    }

    private func previewGesture(
        for choice: HapticChoice,
        selectionMode: HapticSelectionMode
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard hypot(value.translation.width, value.translation.height) <= 12 else {
                    cancelPreviewPress()
                    return
                }
                guard pressedChoice == nil else { return }

                pressedChoice = choice
                previewedChoice = nil
                previewTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard !Task.isCancelled, pressedChoice == choice else { return }
                    previewedChoice = choice
                    sessionManager.previewHaptic(choice)
                }
            }
            .onEnded { _ in
                previewTask?.cancel()
                if pressedChoice == choice, previewedChoice == choice {
                    switch selectionMode {
                    case .steady:
                        sessionManager.steadyHapticChoice = choice
                    case .varied:
                        toggle(choice)
                    }
                }
                pressedChoice = nil
                previewedChoice = nil
                previewTask = nil
            }
    }

    private func cancelPreviewPress() {
        previewTask?.cancel()
        previewTask = nil
        pressedChoice = nil
        previewedChoice = nil
    }

    private func toggle(_ choice: HapticChoice) {
        if sessionManager.selectedHapticChoices.contains(choice) {
            guard sessionManager.selectedHapticChoices.count > 1 else { return }
            sessionManager.selectedHapticChoices.remove(choice)
        } else {
            sessionManager.selectedHapticChoices.insert(choice)
        }
    }
}
