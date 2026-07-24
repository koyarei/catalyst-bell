import SwiftUI

struct CatalystSessionView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var isShowingIntensityIndicator = false
    @State private var indicatorDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if sessionManager.activeVisualStyle == .stillRain {
                RainSurfaceView(
                    events: sessionManager.hapticVisualEvents,
                    isSessionActive: sessionManager.state == .starting || sessionManager.state == .active,
                    intensity: sessionManager.visualIntensity
                )
            } else {
                Color.black
            }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    sessionManager.stop(reason: .userStopped)
                }

            if sessionManager.activeVisualStyle == .stillRain,
               isShowingIntensityIndicator {
                RippleIntensityIndicator(intensity: sessionManager.visualIntensity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, 2)
                    .offset(y: -24)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .focusable()
        .digitalCrownRotation(
            detent: $sessionManager.visualIntensity,
            from: RainVisualIntensity.range.lowerBound,
            through: RainVisualIntensity.range.upperBound,
            by: RainVisualIntensity.crownStep,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true,
            onChange: { _ in
                showIntensityIndicator()
            },
            onIdle: {
                scheduleIntensityIndicatorDismissal()
            }
        )
        .accessibilityLabel("Ripple visibility")
        .accessibilityValue(
            "\(Int((sessionManager.visualIntensity * 100).rounded())) percent"
        )
        .onDisappear {
            indicatorDismissTask?.cancel()
        }
    }

    private func showIntensityIndicator() {
        indicatorDismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.16)) {
            isShowingIntensityIndicator = true
        }
    }

    private func scheduleIntensityIndicatorDismissal() {
        indicatorDismissTask?.cancel()
        indicatorDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.28)) {
                isShowingIntensityIndicator = false
            }
        }
    }
}

private struct RippleIntensityIndicator: View {
    let intensity: Double

    private var normalizedIntensity: Double {
        RainVisualIntensity.clamped(intensity)
    }

    private var percentage: Int {
        Int((normalizedIntensity * 100).rounded())
    }

    var body: some View {
        Text("\(percentage)%")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(.black.opacity(0.72), in: Capsule())
            .accessibilityHidden(true)
    }
}
