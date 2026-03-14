import SwiftUI
import AppKit

struct LogTableView: NSViewRepresentable {
    let entries: [LogEntry]
    @Binding var selectedEntry: LogEntry?
    var autoScroll: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true

        let tableView = NSTableView()
        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = Constants.RowHeight.standard
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.allowsMultipleSelection = false
        tableView.intercellSpacing = NSSize(width: 8, height: 0)

        let columns: [(String, String, CGFloat)] = [
            ("timestamp", "Timestamp", Constants.ColumnWidths.timestamp),
            ("level", "Level", Constants.ColumnWidths.level),
            ("process", "Process", Constants.ColumnWidths.process),
            ("pid", "PID", Constants.ColumnWidths.pid),
            ("subsystem", "Subsystem", Constants.ColumnWidths.subsystem),
            ("category", "Category", Constants.ColumnWidths.category),
            ("sender", "Sender", Constants.ColumnWidths.sender),
            ("message", "Message", Constants.ColumnWidths.message),
        ]

        for (id, title, width) in columns {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            column.minWidth = 40
            if id == "message" {
                column.resizingMask = .autoresizingMask
            }
            tableView.addTableColumn(column)
        }

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator

        scrollView.documentView = tableView
        context.coordinator.tableView = tableView
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        let oldCount = coordinator.entries.count
        coordinator.entries = entries
        coordinator.parent = self

        guard let tableView = coordinator.tableView else { return }

        let clipView = scrollView.contentView
        let contentHeight = tableView.frame.height
        let scrollOffset = clipView.bounds.origin.y + clipView.bounds.height
        let isAtBottom = scrollOffset >= contentHeight - 50

        tableView.reloadData()

        if autoScroll && isAtBottom && entries.count > oldCount && entries.count > 0 {
            tableView.scrollRowToVisible(entries.count - 1)
        }
    }

    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var parent: LogTableView
        var entries: [LogEntry] = []
        weak var tableView: NSTableView?
        weak var scrollView: NSScrollView?

        init(_ parent: LogTableView) {
            self.parent = parent
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            entries.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row < entries.count, let identifier = tableColumn?.identifier else { return nil }

            let entry = entries[row]
            let cellIdentifier = NSUserInterfaceItemIdentifier("LogCell_\(identifier.rawValue)")

            let textField: NSTextField
            if let existing = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTextField {
                textField = existing
            } else {
                textField = NSTextField(labelWithString: "")
                textField.identifier = cellIdentifier
                textField.cell?.truncatesLastVisibleLine = true
                textField.cell?.lineBreakMode = .byTruncatingTail
                textField.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            }

            switch identifier.rawValue {
            case "timestamp":
                textField.stringValue = DateFormatting.displayString(from: entry.timestamp)
            case "level":
                textField.stringValue = entry.logLevel.rawValue
                textField.textColor = NSColor.forLogLevel(entry.logLevel)
                textField.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
            case "process":
                textField.stringValue = entry.processName
            case "pid":
                textField.stringValue = "\(entry.processID)"
            case "subsystem":
                textField.stringValue = entry.subsystem
            case "category":
                textField.stringValue = entry.category
            case "sender":
                textField.stringValue = entry.senderName
            case "message":
                textField.stringValue = entry.eventMessage
            default:
                break
            }

            if identifier.rawValue != "level" {
                textField.textColor = .labelColor
            }

            return textField
        }

        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            Constants.RowHeight.standard
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else { return }
            let row = tableView.selectedRow
            if row >= 0 && row < entries.count {
                parent.selectedEntry = entries[row]
            } else {
                parent.selectedEntry = nil
            }
        }
    }
}
