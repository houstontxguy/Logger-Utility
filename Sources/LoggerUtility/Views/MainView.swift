import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HistoricalView()
                .tabItem {
                    Label("Historical", systemImage: "clock")
                }
                .tag(0)

            StreamView()
                .tabItem {
                    Label("Stream", systemImage: "waveform")
                }
                .tag(1)
        }
        .frame(minWidth: 900, minHeight: 500)
    }
}
