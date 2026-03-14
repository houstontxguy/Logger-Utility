import Foundation

enum ExportService {
    static func exportCSV(entries: [LogEntry], to url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { handle.closeFile() }

        let header = "Timestamp,Level,Process,PID,Subsystem,Category,Sender,Message\n"
        if let headerData = header.data(using: .utf8) {
            handle.write(headerData)
        }

        for entry in entries {
            let line = [
                DateFormatting.fullDisplayString(from: entry.timestamp),
                entry.logLevel.rawValue,
                csvEscape(entry.processName),
                "\(entry.processID)",
                csvEscape(entry.subsystem),
                csvEscape(entry.category),
                csvEscape(entry.senderName),
                csvEscape(entry.eventMessage)
            ].joined(separator: ",") + "\n"

            if let data = line.data(using: .utf8) {
                handle.write(data)
            }
        }
    }

    static func exportPlainText(entries: [LogEntry], to url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { handle.closeFile() }

        for entry in entries {
            let line = "\(DateFormatting.fullDisplayString(from: entry.timestamp)) " +
                       "\(entry.logLevel.rawValue.padding(toLength: 7, withPad: " ", startingAt: 0)) " +
                       "\(entry.processName)[\(entry.processID)] " +
                       "[\(entry.subsystem):\(entry.category)] " +
                       "\(entry.eventMessage)\n"

            if let data = line.data(using: .utf8) {
                handle.write(data)
            }
        }
    }

    private static func csvEscape(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return string
    }
}
