import SwiftUI

struct StreamToolbar: View {
    @ObservedObject var viewModel: StreamViewModel
    @ObservedObject var filterViewModel: FilterViewModel
    @ObservedObject var exportViewModel: ExportViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Start/Stop
            if viewModel.isRunning {
                Button(action: { viewModel.stop() }) {
                    Label("Stop", systemImage: "stop.fill")
                }
                .tint(.red)
            } else {
                Button(action: { viewModel.start() }) {
                    Label("Start", systemImage: "play.fill")
                }
                .tint(.green)
            }

            // Pause/Resume
            Button(action: { viewModel.togglePause() }) {
                Label(
                    viewModel.isPaused ? "Resume" : "Pause",
                    systemImage: viewModel.isPaused ? "play" : "pause"
                )
            }
            .disabled(!viewModel.isRunning)

            // Clear
            Button(action: { viewModel.clear() }) {
                Label("Clear", systemImage: "trash")
            }
            .keyboardShortcut("k", modifiers: .command)

            Divider()

            // Search
            SearchField(text: $viewModel.searchText)
                .frame(maxWidth: 200)

            Divider()

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
        .fixedSize(horizontal: false, vertical: true)
    }
}
