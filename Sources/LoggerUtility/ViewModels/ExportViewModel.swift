import Foundation
import AppKit

@MainActor
final class ExportViewModel: ObservableObject {
    @Published var selectedFormat: ExportFormat = .csv
    @Published var isExporting = false
    @Published var errorMessage: String?
    @Published var isShowingSheet = false

    private let collectService = LogCollectService()

    func export(entries: [LogEntry]) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = []
        panel.nameFieldStringValue = "logs.\(selectedFormat.fileExtension)"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        isExporting = true
        errorMessage = nil

        Task {
            do {
                // Create the file first
                FileManager.default.createFile(atPath: url.path, contents: nil)

                switch selectedFormat {
                case .csv:
                    try ExportService.exportCSV(entries: entries, to: url)
                case .plainText:
                    try ExportService.exportPlainText(entries: entries, to: url)
                case .logarchive:
                    let success = await collectService.collect(
                        outputPath: url.path,
                        lastDuration: "1h"
                    )
                    if !success {
                        errorMessage = collectService.errorMessage ?? "Log collect failed"
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isExporting = false
        }
    }
}
