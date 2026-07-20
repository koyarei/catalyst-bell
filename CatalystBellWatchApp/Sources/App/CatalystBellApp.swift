import SwiftUI

@main
struct CatalystBellApp: App {
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .tint(StillRainPalette.accent)
                .onOpenURL { url in
                    guard url.scheme == "catalystbell" else {
                        return
                    }

                    let source: LaunchSource = url.host == "start" ? .complication : .unknown
                    sessionManager.start(launchSource: source)
                }
        }
    }
}
