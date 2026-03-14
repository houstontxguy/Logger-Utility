import Foundation

struct LogFilter: Equatable {
    var selectedLevels: Set<LogLevel> = Set(LogLevel.allCases)
    var process: String = ""
    var subsystem: String = ""
    var category: String = ""
    var sender: String = ""
    var messageSearch: String = ""
    var predicateClauses: [PredicateClause] = []
    var joinOperator: PredicateJoinOperator = .and
    var rawPredicate: String = ""
    var includeInfo: Bool = false
    var includeDebug: Bool = false
    var includeSource: Bool = false
    var startDate: Date?
    var endDate: Date?

    var isEmpty: Bool {
        process.isEmpty &&
        subsystem.isEmpty &&
        category.isEmpty &&
        sender.isEmpty &&
        messageSearch.isEmpty &&
        predicateClauses.isEmpty &&
        rawPredicate.isEmpty &&
        selectedLevels.count == LogLevel.allCases.count &&
        !includeSource
    }

    var effectivePredicate: String {
        if !rawPredicate.isEmpty {
            return rawPredicate
        }

        var clauses: [String] = []

        if !process.isEmpty {
            clauses.append("process == \"\(process.predicateEscaped)\"")
        }
        if !subsystem.isEmpty {
            clauses.append("subsystem == \"\(subsystem.predicateEscaped)\"")
        }
        if !category.isEmpty {
            clauses.append("category == \"\(category.predicateEscaped)\"")
        }
        if !sender.isEmpty {
            clauses.append("sender == \"\(sender.predicateEscaped)\"")
        }
        if !messageSearch.isEmpty {
            clauses.append("composedMessage CONTAINS[c] \"\(messageSearch.predicateEscaped)\"")
        }

        let userClauses = predicateClauses
            .filter { !$0.value.isEmpty }
            .map { $0.predicateString }
        clauses.append(contentsOf: userClauses)

        if clauses.isEmpty { return "" }

        let join = " \(joinOperator.rawValue) "
        return clauses.joined(separator: join)
    }
}
