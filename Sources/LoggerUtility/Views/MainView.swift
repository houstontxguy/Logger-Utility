import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @State private var showAdminWarning = !isRunningAsAdmin()

    var body: some View {
        VStack(spacing: 0) {
            if showAdminWarning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Running as a standard user. Some log data may be hidden, and .logarchive export requires admin privileges.")
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") {
                        showAdminWarning = false
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                Divider()
            }

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
        }
        .frame(minWidth: 900, minHeight: 500)
    }

    private static func isRunningAsAdmin() -> Bool {
        let uid = getuid()
        // root (0) or member of admin group
        if uid == 0 { return true }
        guard let pw = getpwuid(uid) else { return false }
        let username = String(cString: pw.pointee.pw_name)
        // Check if user is in the admin group
        guard let adminGroup = getgrnam("admin") else { return false }
        var i = 0
        while let member = adminGroup.pointee.gr_mem.advanced(by: i).pointee {
            if String(cString: member) == username { return true }
            i += 1
        }
        return false
    }
}
