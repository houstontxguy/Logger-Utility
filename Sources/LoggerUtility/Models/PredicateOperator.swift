import Foundation

enum PredicateOperator: String, CaseIterable, Identifiable, Codable {
    case equals = "=="
    case notEquals = "!="
    case contains = "CONTAINS"
    case beginsWith = "BEGINSWITH"
    case endsWith = "ENDSWITH"
    case like = "LIKE"
    case matches = "MATCHES"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .equals: return "equals"
        case .notEquals: return "not equals"
        case .contains: return "contains"
        case .beginsWith: return "begins with"
        case .endsWith: return "ends with"
        case .like: return "like"
        case .matches: return "matches"
        }
    }
}
