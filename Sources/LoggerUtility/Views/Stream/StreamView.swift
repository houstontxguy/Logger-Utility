import SwiftUI

struct StreamView: View {
    @StateObject private var viewModel = StreamViewModel()
    @StateObject private var filterViewModel = FilterViewModel()
    @StateObject private var exportViewModel = ExportViewModel()

    var body: some View {
        VStack(spacing: 0) {
            StreamToolbar(
                viewModel: viewModel,
                filterViewModel: filterViewModel,
                exportViewModel: exportViewModel
            )

            Divider()

            HSplitView {
                if filterViewModel.isShowingPanel {
                    FilterPanelView(
                        viewModel: filterViewModel,
                        discoveredSubsystems: viewModel.discoveredSubsystems
                    ) {
                        viewModel.filter = filterViewModel.filter
                        viewModel.selectedEntries = []
                        if viewModel.isRunning {
                            viewModel.stop()
                            viewModel.start()
                        }
                    }
                    .frame(minWidth: 280, maxWidth: 350)
                }

                HSplitView {
                    LogTableView(
                        entries: viewModel.entries,
                        selectedEntries: $viewModel.selectedEntries
                    )

                    if !viewModel.selectedEntries.isEmpty {
                        LogDetailView(entries: viewModel.selectedEntries)
                    }
                }
            }

            Divider()

            StreamStatusBar(viewModel: viewModel)
        }
        .sheet(isPresented: $exportViewModel.isShowingSheet) {
            ExportSheetView(viewModel: exportViewModel, entries: viewModel.entries)
        }
    }
}
