import Foundation

struct LogEntry: Identifiable, Equatable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: UUID
    let timestamp: Date
    let processID: Int
    let processName: String
    let threadID: UInt64
    let logLevel: LogLevel
    let subsystem: String
    let category: String
    let eventMessage: String
    let eventType: EventType
    let senderName: String
    let activityIdentifier: UInt64
    let formatString: String
    let source: String

    init(
        id: UUID = UUID(),
        timestamp: Date,
        processID: Int,
        processName: String,
        threadID: UInt64 = 0,
        logLevel: LogLevel,
        subsystem: String = "",
        category: String = "",
        eventMessage: String,
        eventType: EventType = .logEvent,
        senderName: String = "",
        activityIdentifier: UInt64 = 0,
        formatString: String = "",
        source: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.processID = processID
        self.processName = processName
        self.threadID = threadID
        self.logLevel = logLevel
        self.subsystem = subsystem
        self.category = category
        self.eventMessage = eventMessage
        self.eventType = eventType
        self.senderName = senderName
        self.activityIdentifier = activityIdentifier
        self.formatString = formatString
        self.source = source
    }
}
