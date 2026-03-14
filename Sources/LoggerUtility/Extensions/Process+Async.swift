import Foundation

// Ignore SIGPIPE globally to prevent crashes when child processes terminate
// while we're still reading/writing pipes
private let _ignoreSIGPIPE: Void = {
    signal(SIGPIPE, SIG_IGN)
}()

private let maxLineBufferSize = 10 * 1024 * 1024 // 10MB safety cap

extension Process {
    static func run(
        executablePath: String = "/usr/bin/log",
        arguments: [String],
        onOutput: @escaping (String) -> Void,
        onError: ((String) -> Void)? = nil,
        onTermination: ((Process) -> Void)? = nil
    ) -> Process {
        _ = _ignoreSIGPIPE

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        var stdoutBuffer = Data()
        var stderrBuffer = Data()

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                // EOF — clear handler to avoid zombie
                handle.readabilityHandler = nil
                return
            }

            stdoutBuffer.append(data)

            // Safety cap: discard buffer if a single line exceeds limit
            if stdoutBuffer.count > maxLineBufferSize {
                onError?("Line buffer exceeded \(maxLineBufferSize) bytes, discarding")
                stdoutBuffer.removeAll(keepingCapacity: true)
                return
            }

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
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }

            stderrBuffer.append(data)

            // Process complete lines from stderr buffer
            while let newlineRange = stderrBuffer.range(of: Data([0x0A])) {
                let lineData = stderrBuffer.subdata(in: stderrBuffer.startIndex..<newlineRange.lowerBound)
                stderrBuffer.removeSubrange(stderrBuffer.startIndex...newlineRange.lowerBound)

                if let line = String(data: lineData, encoding: .utf8), !line.isEmpty {
                    onError?(line)
                }
            }
        }

        process.terminationHandler = { proc in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil

            // Flush remaining stderr buffer
            if !stderrBuffer.isEmpty, let remaining = String(data: stderrBuffer, encoding: .utf8), !remaining.isEmpty {
                onError?(remaining)
            }

            onTermination?(proc)
        }

        do {
            try process.run()
        } catch {
            onError?("Failed to launch process: \(error.localizedDescription)")
            onTermination?(process)
        }

        return process
    }

    @discardableResult
    static func runAsync(
        executablePath: String = "/usr/bin/log",
        arguments: [String]
    ) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
        _ = _ignoreSIGPIPE

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { proc in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                continuation.resume(returning: (stdout, stderr, proc.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
