import XCTest
@testable import LoggerUtility

final class LogCommandBuilderTests: XCTestCase {
    func testBasicStreamArguments() {
        let filter = LogFilter()
        let args = LogCommandBuilder.buildStreamArguments(from: filter)
        XCTAssertEqual(args, ["stream", "--style", "ndjson"])
    }

    func testStreamWithInfoAndDebug() {
        var filter = LogFilter()
        filter.includeInfo = true
        filter.includeDebug = true

        let args = LogCommandBuilder.buildStreamArguments(from: filter)
        XCTAssertTrue(args.contains("--info"))
        XCTAssertTrue(args.contains("--debug"))
    }

    func testStreamWithSource() {
        var filter = LogFilter()
        filter.includeSource = true

        let args = LogCommandBuilder.buildStreamArguments(from: filter)
        XCTAssertTrue(args.contains("--source"))
    }

    func testStreamWithSubsystemFilter() {
        var filter = LogFilter()
        filter.subsystem = "com.apple.bluetooth"

        let args = LogCommandBuilder.buildStreamArguments(from: filter)
        XCTAssertTrue(args.contains("--predicate"))
        let predicateIndex = args.firstIndex(of: "--predicate")!
        let predicate = args[predicateIndex + 1]
        XCTAssertEqual(predicate, "subsystem == \"com.apple.bluetooth\"")
    }

    func testShowWithDateRange() {
        var filter = LogFilter()
        let start = DateFormatting.logCommandFormatter.date(from: "2024-01-15 10:00:00")!
        let end = DateFormatting.logCommandFormatter.date(from: "2024-01-15 11:00:00")!
        filter.startDate = start
        filter.endDate = end

        let args = LogCommandBuilder.buildShowArguments(from: filter)
        XCTAssertTrue(args.contains("--start"))
        XCTAssertTrue(args.contains("--end"))
        XCTAssertEqual(args[0], "show")
    }

    func testMultiplePredicateClauses() {
        var filter = LogFilter()
        filter.subsystem = "com.apple.bluetooth"
        filter.process = "bluetoothd"
        filter.joinOperator = .and

        let args = LogCommandBuilder.buildStreamArguments(from: filter)
        XCTAssertTrue(args.contains("--predicate"))
        let predicateIndex = args.firstIndex(of: "--predicate")!
        let predicate = args[predicateIndex + 1]
        XCTAssertTrue(predicate.contains("AND"))
        XCTAssertTrue(predicate.contains("process == \"bluetoothd\""))
        XCTAssertTrue(predicate.contains("subsystem == \"com.apple.bluetooth\""))
    }

    func testRawPredicateOverride() {
        var filter = LogFilter()
        filter.subsystem = "com.apple.bluetooth"
        filter.rawPredicate = "eventMessage CONTAINS \"test\""

        let args = LogCommandBuilder.buildStreamArguments(from: filter)
        let predicateIndex = args.firstIndex(of: "--predicate")!
        let predicate = args[predicateIndex + 1]
        XCTAssertEqual(predicate, "eventMessage CONTAINS \"test\"")
    }

    func testCollectArguments() {
        let args = LogCommandBuilder.buildCollectArguments(outputPath: "/tmp/logs.logarchive", lastDuration: "1h")
        XCTAssertEqual(args, ["collect", "--output", "/tmp/logs.logarchive", "--last", "1h"])
    }
}
