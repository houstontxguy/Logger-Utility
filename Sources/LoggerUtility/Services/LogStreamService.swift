import Foundation
import Combine

final class LogStreamService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?

    let entryPublisher = PassthroughSubject<[LogEntry], Never>()

    private var process: Process?
    private var batchBuffer: [LogEntry] = []
    private var batchTimer: Timer?
    private let batchQueue = DispatchQueue(label: "com.loggerutility.stream.batch")

    func start(filter: LogFilter) {
        stop()

        let args = LogCommandBuilder.buildStreamArguments(from: filter)
        isRunning = true
        errorMessage = nil

        batchTimer = Timer.scheduledTimer(withTimeInterval: Constants.batchInterval, repeats: true) { [weak self] _ in
            self?.flushBatch()
        }

        process = Process.run(
            arguments: args,
            onOutput: { [weak self] line in
                guard let entry = LogParser.parse(line: line) else { return }
                self?.batchQueue.async {
                    self?.batchBuffer.append(entry)
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.errorMessage = error
                }
            },
            onTermination: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.flushBatch()
                    self?.isRunning = false
                    self?.batchTimer?.invalidate()
                    self?.batchTimer = nil
                }
            }
        )
    }

    func stop() {
        if let process = process, process.isRunning {
            process.terminate()
        }
        process = nil
        batchTimer?.invalidate()
        batchTimer = nil
        isRunning = false
    }

    private func flushBatch() {
        batchQueue.async { [weak self] in
            guard let self = self, !self.batchBuffer.isEmpty else { return }
            let batch = self.batchBuffer
            self.batchBuffer.removeAll(keepingCapacity: true)
            DispatchQueue.main.async {
                self.entryPublisher.send(batch)
            }
        }
    }

    deinit {
        stop()
    }
}
