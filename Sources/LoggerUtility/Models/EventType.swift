import Foundation

enum EventType: String, CaseIterable, Identifiable, Codable {
    case logEvent
    case activityCreateEvent
    case activityTransitionEvent
    case signpostEvent
    case stateEvent
    case timesyncEvent
    case traceEvent
    case userActionEvent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .logEvent: return "Log"
        case .activityCreateEvent: return "Activity Create"
        case .activityTransitionEvent: return "Activity Transition"
        case .signpostEvent: return "Signpost"
        case .stateEvent: return "State"
        case .timesyncEvent: return "Timesync"
        case .traceEvent: return "Trace"
        case .userActionEvent: return "User Action"
        }
    }
}
