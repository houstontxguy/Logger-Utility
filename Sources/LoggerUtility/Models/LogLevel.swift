import SwiftUI

enum LogLevel: String, CaseIterable, Identifiable, Codable, Comparable {
    case `default` = "Default"
    case info = "Info"
    case debug = "Debug"
    case error = "Error"
    case fault = "Fault"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .default: return .primary
        case .info: return .blue
        case .debug: return .gray
        case .error: return .orange
        case .fault: return .red
        }
    }

    var nsColor: NSColor {
        switch self {
        case .default: return .labelColor
        case .info: return .systemBlue
        case .debug: return .systemGray
        case .error: return .systemOrange
        case .fault: return .systemRed
        }
    }

    private var sortOrder: Int {
        switch self {
        case .debug: return 0
        case .default: return 1
        case .info: return 2
        case .error: return 3
        case .fault: return 4
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    static func from(_ string: String) -> LogLevel {
        let trimmed = string.trimmingCharacters(in: .whitespaces).lowercased()
        switch trimmed {
        case "default": return .default
        case "info": return .info
        case "debug": return .debug
        case "error": return .error
        case "fault": return .fault
        default: return .default
        }
    }
}
