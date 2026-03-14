import Foundation
import AppKit

@MainActor
enum AIPromptService {
    private static let macOSVersion: String = {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }()

    static var preferredProvider: AIProvider {
        get {
            AIProvider(rawValue: UserDefaults.standard.string(forKey: "preferredAIProvider") ?? "") ?? .perplexity
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "preferredAIProvider")
        }
    }

    static func buildPrompt(for entry: LogEntry) -> String {
        var lines: [String] = []

        lines.append("This is a log entry from a macOS unified log (macOS \(macOSVersion)).")
        lines.append("")
        lines.append("Timestamp: \(DateFormatting.fullDisplayString(from: entry.timestamp))")
        lines.append("Level: \(entry.logLevel.rawValue)")
        lines.append("Process: \(entry.processName) (PID \(entry.processID))")

        if !entry.subsystem.isEmpty {
            lines.append("Subsystem: \(entry.subsystem)")
        }
        if !entry.category.isEmpty {
            lines.append("Category: \(entry.category)")
        }
        if !entry.senderName.isEmpty {
            lines.append("Sender: \(entry.senderName)")
        }

        lines.append("Message: \(entry.eventMessage)")

        if !entry.formatString.isEmpty && entry.formatString != entry.eventMessage {
            lines.append("Format String: \(entry.formatString)")
        }

        lines.append("")
        lines.append("Can you explain what this log message means, what might cause it, and suggest troubleshooting steps?")

        return lines.joined(separator: "\n")
    }

    static func copyPromptToClipboard(for entry: LogEntry) {
        let prompt = buildPrompt(for: entry)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
    }

    static func askAI(about entry: LogEntry, using provider: AIProvider) {
        let prompt = buildPrompt(for: entry)

        if provider.supportsURLQuery {
            // Perplexity supports URL query — open directly with prompt embedded
            let url = provider.url(withPrompt: prompt)
            NSWorkspace.shared.open(url)
        } else {
            // Copy to clipboard and show instructions
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(prompt, forType: .string)

            NSWorkspace.shared.open(provider.baseURL)

            let alert = NSAlert()
            alert.messageText = "Question Copied to Clipboard"
            alert.informativeText = "\(provider.rawValue) is opening in your browser.\n\nPress Cmd+V to paste your question into the chat, then send it."
            alert.alertStyle = .informational
            alert.icon = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
