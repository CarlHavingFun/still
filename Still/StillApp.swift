import SwiftUI

@main
struct StillApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .tint(Theme.accent)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    if phase == .active {
                        appState.appDidBecomeActive()
                    }
                }
        }
    }
}
