import Foundation
import Combine

@MainActor
final class FilterViewModel: ObservableObject {
    @Published var filter = LogFilter()
    @Published var isShowingPanel = false

    func addClause() {
        filter.predicateClauses.append(PredicateClause())
    }

    func removeClause(at offsets: IndexSet) {
        filter.predicateClauses.remove(atOffsets: offsets)
    }

    func removeClause(id: UUID) {
        filter.predicateClauses.removeAll { $0.id == id }
    }

    func reset() {
        filter = LogFilter()
    }

    func toggleLevel(_ level: LogLevel) {
        if filter.selectedLevels.contains(level) {
            filter.selectedLevels.remove(level)
        } else {
            filter.selectedLevels.insert(level)
        }
    }
}
