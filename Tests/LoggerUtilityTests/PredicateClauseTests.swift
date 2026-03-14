import XCTest
@testable import LoggerUtility

final class PredicateClauseTests: XCTestCase {
    func testBasicPredicateString() {
        let clause = PredicateClause(field: .subsystem, op: .equals, value: "com.apple.bluetooth")
        XCTAssertEqual(clause.predicateString, "subsystem == \"com.apple.bluetooth\"")
    }

    func testContainsOperator() {
        let clause = PredicateClause(field: .composedMessage, op: .contains, value: "error")
        XCTAssertEqual(clause.predicateString, "composedMessage CONTAINS \"error\"")
    }

    func testNotEqualsOperator() {
        let clause = PredicateClause(field: .process, op: .notEquals, value: "kernel")
        XCTAssertEqual(clause.predicateString, "process != \"kernel\"")
    }

    func testEscapedQuotes() {
        let clause = PredicateClause(field: .eventMessage, op: .contains, value: "say \"hello\"")
        XCTAssertEqual(clause.predicateString, "eventMessage CONTAINS \"say \\\"hello\\\"\"")
    }

    func testFilterEffectivePredicate() {
        var filter = LogFilter()
        filter.subsystem = "com.apple.bluetooth"
        filter.category = "default"
        filter.joinOperator = .and

        XCTAssertEqual(filter.effectivePredicate, "subsystem == \"com.apple.bluetooth\" AND category == \"default\"")
    }

    func testFilterWithUserClauses() {
        var filter = LogFilter()
        filter.predicateClauses = [
            PredicateClause(field: .composedMessage, op: .contains, value: "error"),
            PredicateClause(field: .process, op: .equals, value: "bluetoothd")
        ]
        filter.joinOperator = .or

        let predicate = filter.effectivePredicate
        XCTAssertTrue(predicate.contains("OR"))
        XCTAssertTrue(predicate.contains("composedMessage CONTAINS \"error\""))
        XCTAssertTrue(predicate.contains("process == \"bluetoothd\""))
    }

    func testEmptyFilterPredicate() {
        let filter = LogFilter()
        XCTAssertTrue(filter.effectivePredicate.isEmpty)
    }

    func testRawPredicateOverrides() {
        var filter = LogFilter()
        filter.subsystem = "com.apple.bluetooth"
        filter.rawPredicate = "custom predicate here"
        XCTAssertEqual(filter.effectivePredicate, "custom predicate here")
    }
}
