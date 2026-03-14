import Foundation

struct RingBuffer<Element> {
    private var storage: [Element]
    private var writeIndex: Int = 0
    private(set) var count: Int = 0
    let capacity: Int

    init(capacity: Int) {
        precondition(capacity > 0, "RingBuffer capacity must be positive")
        self.capacity = capacity
        self.storage = []
        self.storage.reserveCapacity(capacity)
    }

    var isFull: Bool { count == capacity }
    var isEmpty: Bool { count == 0 }

    mutating func append(_ element: Element) {
        if storage.count < capacity {
            storage.append(element)
        } else {
            storage[writeIndex] = element
        }
        writeIndex = (writeIndex + 1) % capacity
        count = min(count + 1, capacity)
    }

    mutating func append(contentsOf elements: [Element]) {
        for element in elements {
            append(element)
        }
    }

    func toArray() -> [Element] {
        guard count > 0 else { return [] }
        if count < capacity {
            return Array(storage)
        }
        let start = writeIndex % capacity
        return Array(storage[start...]) + Array(storage[..<start])
    }

    subscript(index: Int) -> Element {
        precondition(index >= 0 && index < count, "Index out of bounds")
        if count < capacity {
            return storage[index]
        }
        let actualIndex = (writeIndex + index) % capacity
        return storage[actualIndex]
    }

    mutating func clear() {
        storage.removeAll(keepingCapacity: true)
        writeIndex = 0
        count = 0
    }
}
