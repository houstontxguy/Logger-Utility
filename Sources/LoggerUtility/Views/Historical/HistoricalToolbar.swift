import SwiftUI

struct HistoricalToolbar: View {
    @ObservedObject var viewModel: HistoricalViewModel
    @ObservedObject var filterViewModel: FilterViewModel
    @ObservedObject var exportViewModel: ExportViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Quick duration buttons
            Group {
                Button("5m") { viewModel.applyLastDuration(minutes: 5) }
                Button("15m") { viewModel.applyLastDuration(minutes: 15) }
                Button("1h") { viewModel.applyLastDuration(minutes: 60) }
                Button("24h") { viewModel.applyLastDuration(minutes: 1440) }
            }
            .buttonStyle(.bordered)

            Divider()

            // Date pickers
            DatePicker("Start", selection: $viewModel.startDate)
                .labelsHidden()
                .frame(width: 180)

            Text("to")
                .foregroundColor(.secondary)

            DatePicker("End", selection: $viewModel.endDate)
                .labelsHidden()
                .frame(width: 180)

            Divider()

            // Query / Cancel
            if viewModel.isQuerying {
                Button(action: { viewModel.cancel() }) {
                    Label("Cancel", systemImage: "xmark.circle")
                }
                .tint(.red)

                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: { viewModel.query() }) {
                    Label("Query", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            SearchField(text: $viewModel.searchText)
                .frame(maxWidth: 200)

            // Filter toggle
            Button(action: { filterViewModel.isShowingPanel.toggle() }) {
                Label("Filters", systemImage: filterViewModel.isShowingPanel ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }

            // Export
            Button(action: { exportViewModel.isShowingSheet = true }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .keyboardShortcut("e", modifiers: .command)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
