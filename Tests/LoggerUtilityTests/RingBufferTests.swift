import XCTest
@testable import LoggerUtility

final class RingBufferTests: XCTestCase {
    func testInitialState() {
        let buffer = RingBuffer<Int>(capacity: 5)
        XCTAssertTrue(buffer.isEmpty)
        XCTAssertFalse(buffer.isFull)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertEqual(buffer.capacity, 5)
    }

    func testAppendUnderCapacity() {
        var buffer = RingBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)

        XCTAssertEqual(buffer.count, 3)
        XCTAssertFalse(buffer.isFull)
        XCTAssertEqual(buffer.toArray(), [1, 2, 3])
    }

    func testAppendAtCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)

        XCTAssertTrue(buffer.isFull)
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.toArray(), [1, 2, 3])
    }

    func testAppendOverCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)

        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.toArray(), [2, 3, 4])
    }

    func testAppendManyOverCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        for i in 1...10 {
            buffer.append(i)
        }

        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.toArray(), [8, 9, 10])
    }

    func testSubscript() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(10)
        buffer.append(20)
        buffer.append(30)
        buffer.append(40) // wraps: [20, 30, 40]

        XCTAssertEqual(buffer[0], 20)
        XCTAssertEqual(buffer[1], 30)
        XCTAssertEqual(buffer[2], 40)
    }

    func testClear() {
        var buffer = RingBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.clear()

        XCTAssertTrue(buffer.isEmpty)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertEqual(buffer.toArray(), [])
    }

    func testAppendContentsOf() {
        var buffer = RingBuffer<Int>(capacity: 5)
        buffer.append(contentsOf: [1, 2, 3])
        XCTAssertEqual(buffer.toArray(), [1, 2, 3])

        buffer.append(contentsOf: [4, 5, 6])
        XCTAssertEqual(buffer.count, 5)
        XCTAssertEqual(buffer.toArray(), [2, 3, 4, 5, 6])
    }

    func testEmptyToArray() {
        let buffer = RingBuffer<Int>(capacity: 5)
        XCTAssertEqual(buffer.toArray(), [])
    }
}
