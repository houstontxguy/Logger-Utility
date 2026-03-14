import SwiftUI
import AppKit

struct LogTableView: NSViewRepresentable {
    let entries: [LogEntry]
    @Binding var selectedEntry: LogEntry?
    var autoScroll: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedEntry: $selectedEntry)
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
            column.resizingMask = .autoresizingMask
            tableView.addTableColumn(column)
        }

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator

        // Context menu
        let menu = NSMenu()

        let askAIItem = NSMenuItem(title: "Ask AI About This...", action: #selector(Coordinator.askAIAboutEntry(_:)), keyEquivalent: "")
        askAIItem.target = context.coordinator
        menu.addItem(askAIItem)

        let copyPromptItem = NSMenuItem(title: "Copy AI Prompt", action: #selector(Coordinator.copyAIPrompt(_:)), keyEquivalent: "")
        copyPromptItem.target = context.coordinator
        menu.addItem(copyPromptItem)

        menu.addItem(NSMenuItem.separator())

        let copyMessageItem = NSMenuItem(title: "Copy Message", action: #selector(Coordinator.copyMessage(_:)), keyEquivalent: "c")
        copyMessageItem.target = context.coordinator
        menu.addItem(copyMessageItem)

        let copyRowItem = NSMenuItem(title: "Copy Row", action: #selector(Coordinator.copyRow(_:)), keyEquivalent: "")
        copyRowItem.target = context.coordinator
        menu.addItem(copyRowItem)

        tableView.menu = menu

        scrollView.documentView = tableView
        context.coordinator.tableView = tableView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        guard let tableView = coordinator.tableView else { return }

        let oldCount = coordinator.entries.count
        coordinator.entries = entries

        let clipView = scrollView.contentView
        let contentHeight = tableView.frame.height
        let scrollOffset = clipView.bounds.origin.y + clipView.bounds.height
        let isAtBottom = contentHeight <= clipView.bounds.height || scrollOffset >= contentHeight - 50

        tableView.reloadData()

        if autoScroll && isAtBottom && entries.count > oldCount && entries.count > 0 {
            tableView.scrollRowToVisible(entries.count - 1)
        }
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        if let tableView = coordinator.tableView {
            tableView.delegate = nil
            tableView.dataSource = nil
        }
        coordinator.tableView = nil
        coordinator.entries = []
    }

    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var selectedEntry: Binding<LogEntry?>
        var entries: [LogEntry] = []
        weak var tableView: NSTableView?

        init(selectedEntry: Binding<LogEntry?>) {
            self.selectedEntry = selectedEntry
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

            // Reset to defaults
            textField.textColor = .labelColor
            textField.font = .monospacedSystemFont(ofSize: 11, weight: .regular)

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

            return textField
        }

        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            Constants.RowHeight.standard
        }

        // MARK: - Context Menu Actions

        private func entryForMenu() -> LogEntry? {
            guard let tableView = tableView else { return nil }
            let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
            guard row >= 0 && row < entries.count else { return nil }
            return entries[row]
        }

        @objc func askAIAboutEntry(_ sender: Any?) {
            guard let entry = entryForMenu() else { return }
            let provider = AIProvider(rawValue: UserDefaults.standard.string(forKey: "preferredAIProvider") ?? "") ?? .chatgpt
            AIPromptService.askAI(about: entry, using: provider)
        }

        @objc func copyAIPrompt(_ sender: Any?) {
            guard let entry = entryForMenu() else { return }
            AIPromptService.copyPromptToClipboard(for: entry)
        }

        @objc func copyMessage(_ sender: Any?) {
            guard let entry = entryForMenu() else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(entry.eventMessage, forType: .string)
        }

        @objc func copyRow(_ sender: Any?) {
            guard let entry = entryForMenu() else { return }
            let row = "\(DateFormatting.fullDisplayString(from: entry.timestamp))\t" +
                      "\(entry.logLevel.rawValue)\t" +
                      "\(entry.processName)\t\(entry.processID)\t" +
                      "\(entry.subsystem)\t\(entry.category)\t" +
                      "\(entry.senderName)\t\(entry.eventMessage)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(row, forType: .string)
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else { return }
            let row = tableView.selectedRow
            if row >= 0 && row < entries.count {
                selectedEntry.wrappedValue = entries[row]
            } else {
                selectedEntry.wrappedValue = nil
            }
        }
    }
}
