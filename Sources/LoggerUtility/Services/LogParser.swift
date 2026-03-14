import Foundation

enum LogParser {
    static func parse(line: String) -> LogEntry? {
        guard let data = line.data(using: .utf8) else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let timestamp: Date
        if let ts = json["timestamp"] as? String {
            timestamp = DateFormatting.parse(ts) ?? Date()
        } else if let ts = json["machTimestamp"] as? TimeInterval {
            timestamp = Date(timeIntervalSince1970: ts)
        } else {
            timestamp = Date()
        }

        let processID = json["processID"] as? Int ?? 0
        let processName = json["processImagePath"] as? String
            ?? json["process"] as? String
            ?? ""
        let threadID = (json["threadID"] as? NSNumber)?.uint64Value ?? 0

        let levelString = json["messageType"] as? String ?? "Default"
        let logLevel = LogLevel.from(levelString)

        let subsystem = json["subsystem"] as? String ?? ""
        let category = json["category"] as? String ?? ""
        let eventMessage = json["eventMessage"] as? String ?? ""

        let eventTypeString = json["eventType"] as? String ?? "logEvent"
        let eventType = EventType(rawValue: eventTypeString) ?? .logEvent

        let senderName = json["senderImagePath"] as? String
            ?? json["sender"] as? String
            ?? ""
        let activityID = (json["activityIdentifier"] as? NSNumber)?.uint64Value ?? 0
        let formatString = json["formatString"] as? String ?? ""
        let source = json["source"] as? String ?? ""

        let cleanProcessName = (processName as NSString).lastPathComponent
        let cleanSenderName = (senderName as NSString).lastPathComponent

        return LogEntry(
            timestamp: timestamp,
            processID: processID,
            processName: cleanProcessName,
            threadID: threadID,
            logLevel: logLevel,
            subsystem: subsystem,
            category: category,
            eventMessage: eventMessage,
            eventType: eventType,
            senderName: cleanSenderName,
            activityIdentifier: activityID,
            formatString: formatString,
            source: source
        )
    }

    static func parseMultiple(lines: String) -> [LogEntry] {
        lines.components(separatedBy: .newlines)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }
                return parse(line: trimmed)
            }
    }
}
