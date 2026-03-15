import SwiftUI
import AppKit

struct MainView: View {
    @State private var selectedTab = 0
    @State private var showAdminWarning = !isRunningAsAdmin()
    @State private var showFDAWarning = !hasFullDiskAccess()

    var body: some View {
        VStack(spacing: 0) {
            if showFDAWarning {
                warningBanner(
                    icon: "lock.shield",
                    message: "Full Disk Access not granted. Log visibility may be limited.",
                    actionLabel: "Open System Settings",
                    action: { openFDASettings() },
                    onDismiss: { showFDAWarning = false }
                )
                Divider()
            }

            if showAdminWarning {
                warningBanner(
                    icon: "exclamationmark.triangle.fill",
                    message: "Running as a standard user. Some log data may be hidden, and .logarchive export requires admin privileges.",
                    action: nil,
                    onDismiss: { showAdminWarning = false }
                )
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

    private func warningBanner(
        icon: String,
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)?,
        onDismiss: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
            Spacer()
            if let actionLabel = actionLabel, let action = action {
                Button(actionLabel) {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func openFDASettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func hasFullDiskAccess() -> Bool {
        FileManager.default.isReadableFile(atPath: "/Library/Application Support/com.apple.TCC/TCC.db")
    }

    private static func isRunningAsAdmin() -> Bool {
        let uid = getuid()
        if uid == 0 { return true }
        guard let pw = getpwuid(uid) else { return false }
        let username = String(cString: pw.pointee.pw_name)
        guard let adminGroup = getgrnam("admin") else { return false }
        var i = 0
        while let member = adminGroup.pointee.gr_mem.advanced(by: i).pointee {
            if String(cString: member) == username { return true }
            i += 1
        }
        return false
    }
}
