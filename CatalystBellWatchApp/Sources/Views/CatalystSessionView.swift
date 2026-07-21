import SwiftUI

struct CatalystSessionView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        ZStack {
            if sessionManager.activeVisualStyle == .stillRain {
                RainSurfaceView(
                    events: sessionManager.hapticVisualEvents,
                    isSessionActive: sessionManager.state == .starting || sessionManager.state == .active
                )
            } else {
                Color.black
            }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    sessionManager.stop(reason: .userStopped)
                }
        }
        .ignoresSafeArea()
    }
}
