import Foundation
import Combine

@MainActor
final class LogShowService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?

    private var queryTask: Task<[LogEntry], Never>?

    func query(filter: LogFilter) async -> [LogEntry] {
        isRunning = true
        errorMessage = nil

        let args = LogCommandBuilder.buildShowArguments(from: filter)

        do {
            let result = try await PrivilegedProcess.run(arguments: args)

            if result.exitCode != 0 && !result.stderr.isEmpty {
                errorMessage = result.stderr
            }

            // Parse NDJSON output line by line
            let lines = result.stdout.split(separator: "\n", omittingEmptySubsequences: true)
            var entries: [LogEntry] = []
            entries.reserveCapacity(lines.count)

            for line in lines {
                if let entry = LogParser.parse(line: String(line)) {
                    entries.append(entry)
                }
            }

            isRunning = false
            return entries
        } catch {
            isRunning = false
            errorMessage = error.localizedDescription
            return []
        }
    }

    func cancel() {
        queryTask?.cancel()
        queryTask = nil
    }
}
