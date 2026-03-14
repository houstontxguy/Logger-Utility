import Foundation
import Combine

@MainActor
final class HistoricalViewModel: ObservableObject {
    @Published var entries: [LogEntry] = []
    @Published var filter = LogFilter()
    @Published var isQuerying = false
    @Published var errorMessage: String?
    @Published var resultCount = 0
    @Published var queryDuration: TimeInterval = 0
    @Published var searchText = ""
    @Published var selectedEntry: LogEntry?

    // Time range shortcuts
    @Published var startDate = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date()
    @Published var endDate = Date()

    private let showService = LogShowService()
    private var queryTask: Task<Void, Never>?

    func query() {
        queryTask?.cancel()
        entries = []
        resultCount = 0
        errorMessage = nil
        selectedEntry = nil

        filter.startDate = startDate
        filter.endDate = endDate

        let startTime = Date()

        queryTask = Task {
            isQuerying = true
            let results = await showService.query(filter: filter)

            if !Task.isCancelled {
                entries = results
                resultCount = results.count
                queryDuration = Date().timeIntervalSince(startTime)
                errorMessage = showService.errorMessage
            }
            isQuerying = false
        }
    }

    func cancel() {
        queryTask?.cancel()
        showService.cancel()
        isQuerying = false
    }

    func applyLastDuration(minutes: Int) {
        endDate = Date()
        startDate = Calendar.current.date(byAdding: .minute, value: -minutes, to: endDate) ?? endDate
    }

    var filteredEntries: [LogEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.eventMessage.localizedCaseInsensitiveContains(searchText) ||
            $0.processName.localizedCaseInsensitiveContains(searchText) ||
            $0.subsystem.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
}
