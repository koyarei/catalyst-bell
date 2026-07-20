import SwiftUI

enum StillRainPalette {
    static let background = Color(red: 14 / 255, green: 34 / 255, blue: 67 / 255)
    static let primaryButton = Color(red: 45 / 255, green: 111 / 255, blue: 159 / 255)
    static let accent = Color(red: 104 / 255, green: 164 / 255, blue: 204 / 255)
}

struct ContentView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        switch sessionManager.state {
        case .starting, .active, .stopping, .saving:
            CatalystSessionView()
        case .ended, .interrupted:
            HomeView()
        case .idle:
            HomeView()
        }
    }
}
