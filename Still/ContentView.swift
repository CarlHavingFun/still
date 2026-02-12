import SwiftUI

struct ContentView: View {
    @AppStorage("still.language") private var languageRaw: String = AppLanguage.defaultRawValue

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(homeTabTitle, systemImage: "circle")
                }

            MemoryView()
                .tabItem {
                    Label(memoryTabTitle, systemImage: "square.stack")
                }

            SettingsView()
                .tabItem {
                    Label(settingsTabTitle, systemImage: "gearshape")
                }
        }
        .background(Color.clear)
    }

    private var currentLanguage: AppLanguage {
        AppLanguage.resolve(languageRaw)
    }

    private var homeTabTitle: String {
        currentLanguage == .chinese ? "主页" : "Home"
    }

    private var memoryTabTitle: String {
        currentLanguage == .chinese ? "记忆" : "Memory"
    }

    private var settingsTabTitle: String {
        currentLanguage == .chinese ? "设置" : "Settings"
    }
}
