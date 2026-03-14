import Foundation

enum DateFormatting {
    static let logTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static let fullDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    static let logCommandFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func parse(_ string: String) -> Date? {
        if let date = iso8601Formatter.date(from: string) {
            return date
        }
        if let date = logTimestampFormatter.date(from: string) {
            return date
        }
        return nil
    }

    static func displayString(from date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func fullDisplayString(from date: Date) -> String {
        fullDisplayFormatter.string(from: date)
    }

    static func commandString(from date: Date) -> String {
        logCommandFormatter.string(from: date)
    }
}
