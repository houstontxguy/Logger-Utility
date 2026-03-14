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
                    FilterPanelView(viewModel: filterViewModel) {
                        viewModel.filter = filterViewModel.filter
                    }
                    .frame(minWidth: 280, maxWidth: 350)
                }

                HSplitView {
                    LogTableView(
                        entries: viewModel.displayEntries,
                        selectedEntry: $viewModel.selectedEntry,
                        autoScroll: false
                    )

                    if viewModel.selectedEntry != nil {
                        LogDetailView(entry: viewModel.selectedEntry)
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
