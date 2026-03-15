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

    static func buildPrompt(for entries: [LogEntry]) -> String {
        guard !entries.isEmpty else { return "" }
        if entries.count == 1 { return buildPrompt(for: entries[0]) }

        let capped = Array(entries.prefix(50))
        var lines: [String] = []

        let sorted = capped.sorted { $0.timestamp < $1.timestamp }
        guard let first = sorted.first, let last = sorted.last else { return "" }
        let earliest = DateFormatting.fullDisplayString(from: first.timestamp)
        let latest = DateFormatting.fullDisplayString(from: last.timestamp)

        lines.append("These are \(capped.count) log entries from a macOS unified log (macOS \(macOSVersion)).")
        if entries.count > 50 {
            lines.append("(Showing first 50 of \(entries.count) selected entries.)")
        }
        lines.append("Time range: \(earliest) to \(latest)")
        lines.append("")

        for (i, entry) in sorted.enumerated() {
            lines.append("--- Entry \(i + 1) ---")
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
        }

        lines.append("Analyze these entries together. Explain what they indicate, identify patterns, and suggest troubleshooting steps.")

        return lines.joined(separator: "\n")
    }

    static func copyPromptToClipboard(for entries: [LogEntry]) {
        let prompt = buildPrompt(for: entries)
        copyToClipboard(prompt)
    }

    static func askAI(about entries: [LogEntry], using provider: AIProvider) {
        guard !entries.isEmpty else { return }
        let prompt = buildPrompt(for: entries)

        if provider.supportsURLQuery {
            let url = provider.url(withPrompt: prompt)
            let urlString = url.absoluteString
            if urlString.count > 2048 {
                copyToClipboard(prompt)
                NSWorkspace.shared.open(provider.baseURL)
                showClipboardAlert(
                    title: "Prompt Copied to Clipboard",
                    message: "The prompt is too long for a URL. \(provider.rawValue) is opening in your browser.\n\nPress Cmd+V to paste your question."
                )
            } else {
                NSWorkspace.shared.open(url)
            }
        } else {
            copyToClipboard(prompt)
            NSWorkspace.shared.open(provider.baseURL)
            showClipboardAlert(
                title: "Question Copied to Clipboard",
                message: "\(provider.rawValue) is opening in your browser.\n\nPress Cmd+V to paste your question into the chat, then send it."
            )
        }
    }

    // MARK: - Private Helpers

    private static func copyToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    private static func showClipboardAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
