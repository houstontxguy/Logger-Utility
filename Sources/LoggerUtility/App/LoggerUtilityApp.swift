import SwiftUI

@main
struct LoggerUtilityApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Logs") {
                Button("Clear Logs") {
                    NotificationCenter.default.post(name: .clearLogs, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("Search") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Export...") {
                    NotificationCenter.default.post(name: .exportLogs, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)

                Divider()

                Button("Ask AI About Selected Log") {
                    NotificationCenter.default.post(name: .askAI, object: nil)
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])

                Button("Copy AI Prompt") {
                    NotificationCenter.default.post(name: .copyAIPrompt, object: nil)
                }
            }
        }
    }
}

extension Notification.Name {
    static let clearLogs = Notification.Name("clearLogs")
    static let focusSearch = Notification.Name("focusSearch")
    static let exportLogs = Notification.Name("exportLogs")
    static let askAI = Notification.Name("askAI")
    static let copyAIPrompt = Notification.Name("copyAIPrompt")
}
