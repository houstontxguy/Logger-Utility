import Foundation

enum DateFormatting {
    // Thread-safe lock for DateFormatter access
    private static let lock = NSLock()

    private static let _logTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let _displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private static let _fullDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private static let _logCommandFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // ISO8601DateFormatter is thread-safe
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // Expose logCommandFormatter for tests that need direct access
    static var logCommandFormatter: DateFormatter { _logCommandFormatter }

    static func parse(_ string: String) -> Date? {
        // ISO8601DateFormatter is thread-safe, no lock needed
        if let date = iso8601Formatter.date(from: string) {
            return date
        }
        lock.lock()
        defer { lock.unlock() }
        if let date = _logTimestampFormatter.date(from: string) {
            return date
        }
        return nil
    }

    static func displayString(from date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }
        return _displayFormatter.string(from: date)
    }

    static func fullDisplayString(from date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }
        return _fullDisplayFormatter.string(from: date)
    }

    static func commandString(from date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }
        return _logCommandFormatter.string(from: date)
    }
}
