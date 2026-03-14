import XCTest
@testable import LoggerUtility

final class LogParserTests: XCTestCase {
    func testParseValidNDJSON() {
        let json = """
        {"timestamp":"2024-01-15 10:30:00.123456-0600","processID":123,"processImagePath":"/usr/sbin/bluetoothd","threadID":456,"messageType":"Error","subsystem":"com.apple.bluetooth","category":"default","eventMessage":"Connection failed","eventType":"logEvent","senderImagePath":"/usr/lib/libbluetooth.dylib","activityIdentifier":0,"formatString":"%s","source":""}
        """

        let entry = LogParser.parse(line: json)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.processID, 123)
        XCTAssertEqual(entry?.processName, "bluetoothd")
        XCTAssertEqual(entry?.logLevel, .error)
        XCTAssertEqual(entry?.subsystem, "com.apple.bluetooth")
        XCTAssertEqual(entry?.category, "default")
        XCTAssertEqual(entry?.eventMessage, "Connection failed")
        XCTAssertEqual(entry?.eventType, .logEvent)
        XCTAssertEqual(entry?.senderName, "libbluetooth.dylib")
    }

    func testParseInvalidJSON() {
        let entry = LogParser.parse(line: "not json at all")
        XCTAssertNil(entry)
    }

    func testParseEmptyJSON() {
        let entry = LogParser.parse(line: "{}")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.processID, 0)
        XCTAssertEqual(entry?.logLevel, .default)
        XCTAssertEqual(entry?.eventMessage, "")
    }

    func testParseMultipleLines() {
        let lines = """
        {"processID":1,"processImagePath":"a","messageType":"Info","eventMessage":"msg1","eventType":"logEvent"}
        {"processID":2,"processImagePath":"b","messageType":"Error","eventMessage":"msg2","eventType":"logEvent"}
        """

        let entries = LogParser.parseMultiple(lines: lines)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].processID, 1)
        XCTAssertEqual(entries[1].processID, 2)
    }

    func testParseLogLevels() {
        let levels = ["Default", "Info", "Debug", "Error", "Fault"]
        let expected: [LogLevel] = [.default, .info, .debug, .error, .fault]

        for (levelStr, expectedLevel) in zip(levels, expected) {
            let json = "{\"messageType\":\"\(levelStr)\",\"eventType\":\"logEvent\"}"
            let entry = LogParser.parse(line: json)
            XCTAssertEqual(entry?.logLevel, expectedLevel, "Failed for level: \(levelStr)")
        }
    }

    func testParseISO8601Timestamp() {
        let json = """
        {"timestamp":"2024-01-15T16:30:00.123456Z","processID":1,"eventMessage":"test","eventType":"logEvent"}
        """
        let entry = LogParser.parse(line: json)
        XCTAssertNotNil(entry)
        XCTAssertNotNil(entry?.timestamp)
    }
}
