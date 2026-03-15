import Foundation

@MainActor
final class LogCollectService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?

    func collect(outputPath: String, lastDuration: String? = nil, startDate: Date? = nil) async -> Bool {
        isRunning = true
        errorMessage = nil

        let args = LogCommandBuilder.buildCollectArguments(
            outputPath: outputPath,
            lastDuration: lastDuration,
            startDate: startDate
        )

        do {
            let result = try await Process.runAsync(arguments: args)
            isRunning = false
            if result.exitCode != 0 {
                errorMessage = result.stderr.isEmpty ? "log collect failed with exit code \(result.exitCode)" : result.stderr
                return false
            }
            return true
        } catch {
            isRunning = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
