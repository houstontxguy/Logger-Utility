import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case logarchive = "Log Archive (.logarchive)"
    case csv = "CSV (.csv)"
    case plainText = "Plain Text (.txt)"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .logarchive: return "logarchive"
        case .csv: return "csv"
        case .plainText: return "txt"
        }
    }
}
