import SwiftUI

struct ExportSheetView: View {
    @ObservedObject var viewModel: ExportViewModel
    let entries: [LogEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Export Logs")
                .font(.headline)

            Picker("Format", selection: $viewModel.selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.radioGroup)

            if viewModel.selectedFormat == .logarchive {
                Text("Log archive export uses `log collect` and may require administrator privileges.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(entries.count) entries will be exported.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Export...") {
                    viewModel.export(entries: entries)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isExporting)
            }
        }
        .padding()
        .frame(width: 350)
    }
}
