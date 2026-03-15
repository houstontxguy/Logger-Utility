import Foundation
import AppKit

/// Runs shell commands with administrator privileges using the macOS authorization dialog.
/// Uses AppleScript's `do shell script ... with administrator privileges` which shows
/// the standard macOS admin username/password prompt.
enum PrivilegedProcess {
    /// Run a command with admin privileges. Returns (stdout, stderr, exitCode).
    /// Shows the macOS admin authentication dialog if needed.
    static func run(executablePath: String = "/usr/bin/log", arguments: [String]) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
        // Build the shell command with proper escaping
        let escapedArgs = arguments.map { escapeForShell($0) }
        let command = ([executablePath] + escapedArgs).joined(separator: " ")

        let script = """
        do shell script "\(escapeForAppleScript(command))" with administrator privileges
        """

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let appleScript = NSAppleScript(source: script)
                let result = appleScript?.executeAndReturnError(&error)

                if let error = error {
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Authorization failed"
                    let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? -1

                    // -128 = user cancelled the auth dialog
                    if errorNumber == -128 {
                        continuation.resume(returning: ("", "User cancelled authorization", 1))
                    } else {
                        continuation.resume(returning: ("", errorMessage, 1))
                    }
                } else {
                    let stdout = result?.stringValue ?? ""
                    continuation.resume(returning: (stdout, "", 0))
                }
            }
        }
    }

    /// Escape a string for use inside a single-quoted shell argument
    private static func escapeForShell(_ string: String) -> String {
        // If the string contains no special characters, return as-is
        let safe = string.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." || $0 == "/" || $0 == ":" || $0 == "," }
        if safe { return string }
        // Wrap in single quotes, escaping any single quotes within
        let escaped = string.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    /// Escape a string for use inside an AppleScript double-quoted string
    private static func escapeForAppleScript(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
