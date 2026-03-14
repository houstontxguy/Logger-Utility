import SwiftUI

extension Color {
    static func forLogLevel(_ level: LogLevel) -> Color {
        level.color
    }
}

extension NSColor {
    static func forLogLevel(_ level: LogLevel) -> NSColor {
        level.nsColor
    }
}
