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

        let format = selectedFormat
        let entriesToExport = entries

        isExporting = true
        errorMessage = nil

        Task { @MainActor in
            do {
                FileManager.default.createFile(atPath: url.path, contents: nil)

                switch format {
                case .csv:
                    try ExportService.exportCSV(entries: entriesToExport, to: url)
                case .plainText:
                    try ExportService.exportPlainText(entries: entriesToExport, to: url)
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
