import Foundation
import Combine

final class LogShowService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?

    private var process: Process?

    func query(filter: LogFilter) async -> [LogEntry] {
        await MainActor.run {
            isRunning = true
            errorMessage = nil
        }

        let args = LogCommandBuilder.buildShowArguments(from: filter)
        var entries: [LogEntry] = []

        let entriesLock = NSLock()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let proc = Process.run(
                arguments: args,
                onOutput: { line in
                    if let entry = LogParser.parse(line: line) {
                        entriesLock.lock()
                        entries.append(entry)
                        entriesLock.unlock()
                    }
                },
                onError: { [weak self] error in
                    DispatchQueue.main.async {
                        self?.errorMessage = error
                    }
                },
                onTermination: { _ in
                    continuation.resume()
                }
            )
            self.process = proc
        }

        await MainActor.run {
            isRunning = false
        }

        return entries
    }

    func cancel() {
        if let process = process, process.isRunning {
            process.terminate()
        }
        process = nil
    }

    deinit {
        cancel()
    }
}
