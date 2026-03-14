import Foundation

struct PredicateClause: Identifiable, Equatable, Codable {
    let id: UUID
    var field: PredicateField
    var op: PredicateOperator
    var value: String

    init(id: UUID = UUID(), field: PredicateField = .subsystem, op: PredicateOperator = .equals, value: String = "") {
        self.id = id
        self.field = field
        self.op = op
        self.value = value
    }

    var predicateString: String {
        let escapedValue = value.predicateEscaped
        return "\(field.rawValue) \(op.rawValue) \"\(escapedValue)\""
    }
}

enum PredicateJoinOperator: String, CaseIterable, Identifiable, Codable {
    case and = "AND"
    case or = "OR"

    var id: String { rawValue }
}
