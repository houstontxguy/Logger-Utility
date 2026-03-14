import Foundation
import Combine

/// Thread-safe batch accumulator for log entries
private final class EntryBatch: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.loggerutility.stream.batch")
    private var buffer: [LogEntry] = []

    func append(_ entry: LogEntry) {
        queue.async { self.buffer.append(entry) }
    }

    func flush() -> [LogEntry] {
        queue.sync {
            guard !buffer.isEmpty else { return [] }
            let batch = buffer
            buffer.removeAll(keepingCapacity: true)
            return batch
        }
    }
}

@MainActor
final class LogStreamService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?

    let entryPublisher = PassthroughSubject<[LogEntry], Never>()

    private var process: Process?
    private var batchTimer: Timer?
    private var batch = EntryBatch()

    func start(filter: LogFilter) {
        stop()

        let args = LogCommandBuilder.buildStreamArguments(from: filter)
        isRunning = true
        errorMessage = nil
        batch = EntryBatch()

        let currentBatch = batch
        batchTimer = Timer.scheduledTimer(withTimeInterval: Constants.batchInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.flushBatch()
            }
        }

        process = Process.run(
            arguments: args,
            onOutput: { line in
                guard let entry = LogParser.parse(line: line) else { return }
                currentBatch.append(entry)
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.errorMessage = error
                }
            },
            onTermination: { [weak self] _ in
                Task { @MainActor in
                    self?.flushBatch()
                    self?.isRunning = false
                    self?.batchTimer?.invalidate()
                    self?.batchTimer = nil
                }
            }
        )
    }

    func stop() {
        batchTimer?.invalidate()
        batchTimer = nil
        if let process = process, process.isRunning {
            process.terminate()
        }
        process = nil
        isRunning = false
    }

    private func flushBatch() {
        let entries = batch.flush()
        guard !entries.isEmpty else { return }
        entryPublisher.send(entries)
    }

    deinit {
        batchTimer?.invalidate()
        if let process = process, process.isRunning {
            process.terminate()
        }
    }
}
