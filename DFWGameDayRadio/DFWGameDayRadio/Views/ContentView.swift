import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StationPickerView()
                .tabItem {
                    Label("Stations", systemImage: "radio")
                }

            GameListView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
