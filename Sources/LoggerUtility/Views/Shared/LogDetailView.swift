import SwiftUI

struct LogDetailView: View {
    let entry: LogEntry?

    var body: some View {
        Group {
            if let entry = entry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        detailSection("Message", entry.eventMessage, isMessage: true)
                        detailRow("Timestamp", DateFormatting.fullDisplayString(from: entry.timestamp))
                        detailRow("Level", entry.logLevel.rawValue, color: entry.logLevel.color)
                        detailRow("Process", "\(entry.processName) (\(entry.processID))")
                        detailRow("Thread", "\(entry.threadID)")
                        detailRow("Subsystem", entry.subsystem)
                        detailRow("Category", entry.category)
                        detailRow("Sender", entry.senderName)
                        detailRow("Event Type", entry.eventType.displayName)

                        if entry.activityIdentifier != 0 {
                            detailRow("Activity ID", "\(entry.activityIdentifier)")
                        }
                        if !entry.formatString.isEmpty {
                            detailSection("Format String", entry.formatString)
                        }
                        if !entry.source.isEmpty {
                            detailRow("Source", entry.source)
                        }
                    }
                    .padding()
                }
            } else {
                VStack {
                    Spacer()
                    Text("Select a log entry to view details")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 250)
    }

    private func detailRow(_ label: String, _ value: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(color)
                .textSelection(.enabled)
        }
    }

    private func detailSection(_ label: String, _ value: String, isMessage: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.system(isMessage ? .body : .caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
        }
    }
}
