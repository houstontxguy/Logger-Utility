import SwiftUI
import AppKit

struct LogTableView: NSViewRepresentable {
    let entries: [LogEntry]
    @Binding var selectedEntries: [LogEntry]
    var autoScroll: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedEntries: $selectedEntries)
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
        tableView.allowsMultipleSelection = true
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
        menu.delegate = context.coordinator

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

        // Sync programmatic selection clears back to NSTableView (Bug #2)
        if selectedEntries.isEmpty && tableView.numberOfSelectedRows > 0 {
            coordinator.isSuppressingSelectionChange = true
            tableView.deselectAll(nil)
            coordinator.isSuppressingSelectionChange = false
        }

        let clipView = scrollView.contentView
        let contentHeight = tableView.frame.height
        let scrollOffset = clipView.bounds.origin.y + clipView.bounds.height
        let isAtBottom = contentHeight <= clipView.bounds.height || scrollOffset >= contentHeight - 50

        // Save selected entry IDs to restore after reload (Bug #1)
        let selectedIDs = Set(selectedEntries.map(\.id))

        coordinator.isSuppressingSelectionChange = true
        tableView.reloadData()

        // Restore selection by matching entry IDs in the new data
        if !selectedIDs.isEmpty {
            let indexSet = NSMutableIndexSet()
            for (index, entry) in entries.enumerated() {
                if selectedIDs.contains(entry.id) {
                    indexSet.add(index)
                }
            }
            if indexSet.count > 0 {
                tableView.selectRowIndexes(indexSet as IndexSet, byExtendingSelection: false)
            }
        }
        // If entries rotated out and selection is now empty, update the binding
        if !selectedIDs.isEmpty && tableView.numberOfSelectedRows == 0 {
            coordinator.selectedEntries.wrappedValue = []
        }
        coordinator.isSuppressingSelectionChange = false

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

    @MainActor
    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate {
        var selectedEntries: Binding<[LogEntry]>
        var entries: [LogEntry] = []
        weak var tableView: NSTableView?
        var isSuppressingSelectionChange = false

        init(selectedEntries: Binding<[LogEntry]>) {
            self.selectedEntries = selectedEntries
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

        // MARK: - Selection

        private func entriesForMenu() -> [LogEntry] {
            guard let tableView = tableView else { return [] }
            let clickedRow = tableView.clickedRow

            if clickedRow >= 0 && clickedRow < entries.count {
                // If clicked row is part of the current selection, use full selection
                if tableView.selectedRowIndexes.contains(clickedRow) {
                    return tableView.selectedRowIndexes.compactMap { idx in
                        idx < entries.count ? entries[idx] : nil
                    }
                }
                // Otherwise just the clicked row
                return [entries[clickedRow]]
            }

            // Fallback to current selection
            return tableView.selectedRowIndexes.compactMap { idx in
                idx < entries.count ? entries[idx] : nil
            }
        }

        // MARK: - NSMenuDelegate

        func menuNeedsUpdate(_ menu: NSMenu) {
            let selected = entriesForMenu()
            let count = selected.count

            if let askItem = menu.items.first(where: { $0.action == #selector(askAIAboutEntry(_:)) }) {
                askItem.title = count > 1
                    ? "Ask AI About Selected Logs (\(count))"
                    : "Ask AI About This..."
            }
            if let copyPromptItem = menu.items.first(where: { $0.action == #selector(copyAIPrompt(_:)) }) {
                copyPromptItem.title = count > 1
                    ? "Copy AI Prompt (\(count) entries)"
                    : "Copy AI Prompt"
            }
        }

        // MARK: - Context Menu Actions

        @objc func askAIAboutEntry(_ sender: Any?) {
            let selected = entriesForMenu()
            guard !selected.isEmpty else { return }
            AIPromptService.askAI(about: selected, using: AIPromptService.preferredProvider)
        }

        @objc func copyAIPrompt(_ sender: Any?) {
            let selected = entriesForMenu()
            guard !selected.isEmpty else { return }
            AIPromptService.copyPromptToClipboard(for: selected)
        }

        @objc func copyMessage(_ sender: Any?) {
            let selected = entriesForMenu()
            guard !selected.isEmpty else { return }
            let text = selected.map(\.eventMessage).joined(separator: "\n")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }

        @objc func copyRow(_ sender: Any?) {
            let selected = entriesForMenu()
            guard !selected.isEmpty else { return }
            let text = selected.map { entry in
                "\(DateFormatting.fullDisplayString(from: entry.timestamp))\t" +
                "\(entry.logLevel.rawValue)\t" +
                "\(entry.processName)\t\(entry.processID)\t" +
                "\(entry.subsystem)\t\(entry.category)\t" +
                "\(entry.senderName)\t\(entry.eventMessage)"
            }.joined(separator: "\n")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard !isSuppressingSelectionChange else { return }
            guard let tableView = notification.object as? NSTableView else { return }
            let indexes = tableView.selectedRowIndexes
            selectedEntries.wrappedValue = indexes.compactMap { idx in
                idx < entries.count ? entries[idx] : nil
            }
        }
    }
}
