import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        switch sessionManager.state {
        case .starting, .active, .stopping, .saving:
            CatalystSessionView()
        case .ended, .interrupted:
            DarkIdleView()
        case .idle:
            HomeView()
        }
    }
}
