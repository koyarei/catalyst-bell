import SwiftUI

struct CatalystSessionView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                sessionManager.stop(reason: .userStopped)
            }
    }
}
