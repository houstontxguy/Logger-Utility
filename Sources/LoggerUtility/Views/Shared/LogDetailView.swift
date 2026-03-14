import SwiftUI

struct LogDetailView: View {
    let entry: LogEntry?
    @State private var showCopiedFeedback = false
    @State private var feedbackTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let entry = entry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Ask AI section
                        HStack(spacing: 8) {
                            Menu {
                                ForEach(AIProvider.allCases) { provider in
                                    Button(provider.rawValue) {
                                        AIPromptService.preferredProvider = provider
                                        AIPromptService.askAI(about: entry, using: provider)
                                    }
                                }
                            } label: {
                                Label("Ask AI (\(AIPromptService.preferredProvider.rawValue))", systemImage: "brain")
                            }
                            .menuStyle(.borderedButton)

                            Button {
                                AIPromptService.askAI(about: entry, using: AIPromptService.preferredProvider)
                            } label: {
                                Label("Open", systemImage: "arrow.up.right.square")
                            }

                            Button {
                                AIPromptService.copyPromptToClipboard(for: entry)
                                showCopiedFeedback = true
                                feedbackTask?.cancel()
                                feedbackTask = Task {
                                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                                    if !Task.isCancelled {
                                        showCopiedFeedback = false
                                    }
                                }
                            } label: {
                                Label(showCopiedFeedback ? "Copied!" : "Copy Prompt", systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            }
                        }
                        .controlSize(.small)

                        Divider()

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
        .onDisappear {
            feedbackTask?.cancel()
        }
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
