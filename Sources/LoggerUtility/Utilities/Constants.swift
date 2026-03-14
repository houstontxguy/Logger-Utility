import Foundation

enum Constants {
    static let defaultStreamBufferCapacity = 100_000
    static let batchInterval: TimeInterval = 0.1 // 100ms
    static let searchDebounceInterval: TimeInterval = 0.3 // 300ms
    static let maxExportBatchSize = 10_000

    enum ColumnWidths {
        static let timestamp: CGFloat = 120
        static let level: CGFloat = 60
        static let process: CGFloat = 120
        static let pid: CGFloat = 55
        static let subsystem: CGFloat = 180
        static let category: CGFloat = 120
        static let sender: CGFloat = 120
        static let message: CGFloat = 500
    }

    enum RowHeight {
        static let standard: CGFloat = 20
    }
}
