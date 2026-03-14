import Foundation

enum PredicateField: String, CaseIterable, Identifiable, Codable {
    case process
    case processID = "processID"
    case subsystem
    case category
    case composedMessage
    case eventMessage
    case sender
    case eventType
    case messageType

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .process: return "Process"
        case .processID: return "Process ID"
        case .subsystem: return "Subsystem"
        case .category: return "Category"
        case .composedMessage: return "Composed Message"
        case .eventMessage: return "Event Message"
        case .sender: return "Sender"
        case .eventType: return "Event Type"
        case .messageType: return "Message Type"
        }
    }
}
