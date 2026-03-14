import Foundation
import Combine

@MainActor
final class HistoricalViewModel: ObservableObject {
    @Published var entries: [LogEntry] = []
    @Published var displayEntries: [LogEntry] = []
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
    private var cancellables = Set<AnyCancellable>()
    private var searchDebounce: AnyCancellable?

    init() {
        // Debounce search text and rebuild filtered results
        searchDebounce = $searchText
            .debounce(for: .seconds(Constants.searchDebounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildDisplayEntries()
            }
    }

    func query() {
        queryTask?.cancel()
        showService.cancel()

        entries = []
        displayEntries = []
        resultCount = 0
        errorMessage = nil
        selectedEntry = nil

        filter.startDate = startDate
        filter.endDate = endDate

        let startTime = Date()
        let currentFilter = filter

        queryTask = Task {
            isQuerying = true
            let results = await showService.query(filter: currentFilter)

            guard !Task.isCancelled else {
                isQuerying = false
                return
            }

            entries = results
            resultCount = results.count
            queryDuration = Date().timeIntervalSince(startTime)
            errorMessage = showService.errorMessage
            rebuildDisplayEntries()
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

    private func rebuildDisplayEntries() {
        guard !searchText.isEmpty else {
            displayEntries = entries
            return
        }
        let search = searchText
        displayEntries = entries.filter {
            $0.eventMessage.localizedCaseInsensitiveContains(search) ||
            $0.processName.localizedCaseInsensitiveContains(search) ||
            $0.subsystem.localizedCaseInsensitiveContains(search) ||
            $0.category.localizedCaseInsensitiveContains(search)
        }
    }
}
