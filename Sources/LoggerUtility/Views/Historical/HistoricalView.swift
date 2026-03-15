import SwiftUI

struct HistoricalView: View {
    @StateObject private var viewModel = HistoricalViewModel()
    @StateObject private var filterViewModel = FilterViewModel()
    @StateObject private var exportViewModel = ExportViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HistoricalToolbar(
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
                    }
                    .frame(minWidth: 280, maxWidth: 350)
                }

                HSplitView {
                    LogTableView(
                        entries: viewModel.displayEntries,
                        selectedEntries: $viewModel.selectedEntries,
                        autoScroll: false
                    )

                    if !viewModel.selectedEntries.isEmpty {
                        LogDetailView(entries: viewModel.selectedEntries)
                    }
                }
            }

            Divider()

            QueryStatusBar(viewModel: viewModel)
        }
        .sheet(isPresented: $exportViewModel.isShowingSheet) {
            ExportSheetView(viewModel: exportViewModel, entries: viewModel.displayEntries)
        }
    }
}
