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
            AIProvider(rawValue: UserDefaults.standard.string(forKey: "preferredAIProvider") ?? "") ?? .chatgpt
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
        copyPromptToClipboard(for: entry)
        NSWorkspace.shared.open(provider.url)
    }
}
