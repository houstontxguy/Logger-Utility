import Foundation

final class LogCollectService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?

    func collect(outputPath: String, lastDuration: String? = nil, startDate: Date? = nil) async -> Bool {
        await MainActor.run {
            isRunning = true
            errorMessage = nil
        }

        let args = LogCommandBuilder.buildCollectArguments(
            outputPath: outputPath,
            lastDuration: lastDuration,
            startDate: startDate
        )

        do {
            let result = try await Process.runAsync(arguments: args)
            await MainActor.run {
                isRunning = false
                if !result.stderr.isEmpty && result.stderr.contains("Error") {
                    errorMessage = result.stderr
                }
            }
            return result.stderr.isEmpty || !result.stderr.contains("Error")
        } catch {
            await MainActor.run {
                isRunning = false
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
