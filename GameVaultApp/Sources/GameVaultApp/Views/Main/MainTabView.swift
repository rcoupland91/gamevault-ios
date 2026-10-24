import SwiftUI

struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "chart.bar.fill", value: 0) {
                DashboardView(authVM: authVM)
            }
            Tab("Playing", systemImage: "gamecontroller.fill", value: 1) {
                NowPlayingView()
            }
            Tab("Library", systemImage: "books.vertical.fill", value: 2) {
                GameLibraryView()
            }
            Tab("Backlog", systemImage: "bookmark.fill", value: 3) {
                BacklogView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 4) {
                SettingsView(authVM: authVM)
            }
        }
        .tint(.accentColor)
    }
}
