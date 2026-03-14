import Foundation

extension Process {
    static func run(
        executablePath: String = "/usr/bin/log",
        arguments: [String],
        onOutput: @escaping (String) -> Void,
        onError: ((String) -> Void)? = nil,
        onTermination: ((Process) -> Void)? = nil
    ) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        var stdoutBuffer = Data()

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            stdoutBuffer.append(data)

            while let newlineRange = stdoutBuffer.range(of: Data([0x0A])) {
                let lineData = stdoutBuffer.subdata(in: stdoutBuffer.startIndex..<newlineRange.lowerBound)
                stdoutBuffer.removeSubrange(stdoutBuffer.startIndex...newlineRange.lowerBound)

                if let line = String(data: lineData, encoding: .utf8), !line.isEmpty {
                    onOutput(line)
                }
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let str = String(data: data, encoding: .utf8) {
                onError?(str)
            }
        }

        process.terminationHandler = { proc in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            onTermination?(proc)
        }

        do {
            try process.run()
        } catch {
            onError?("Failed to launch process: \(error.localizedDescription)")
        }

        return process
    }

    @discardableResult
    static func runAsync(
        executablePath: String = "/usr/bin/log",
        arguments: [String]
    ) async throws -> (stdout: String, stderr: String) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { _ in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                continuation.resume(returning: (stdout, stderr))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
