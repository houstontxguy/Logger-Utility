import SwiftUI

struct LogDetailView: View {
    let entries: [LogEntry]
    @AppStorage("preferredAIProvider") private var preferredProviderRaw: String = AIProvider.perplexity.rawValue
    @State private var showCopiedFeedback = false
    @State private var feedbackTask: Task<Void, Never>?

    private var preferredProvider: AIProvider {
        AIProvider(rawValue: preferredProviderRaw) ?? .perplexity
    }

    var body: some View {
        Group {
            if entries.count > 1 {
                multiEntryView
            } else if let entry = entries.first {
                singleEntryView(entry)
            } else {
                VStack {
                    Spacer()
                    Text("Select a log entry to view details")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 250)
        .onDisappear {
            feedbackTask?.cancel()
        }
    }

    private func singleEntryView(_ entry: LogEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                askAISection(entries: [entry])

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
    }

    private var multiEntryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                askAISection(entries: entries)

                Divider()

                let sorted = entries.sorted { $0.timestamp < $1.timestamp }

                detailRow("Selected Entries", "\(entries.count)")

                if let first = sorted.first, let last = sorted.last {
                    detailRow("Time Range",
                        "\(DateFormatting.fullDisplayString(from: first.timestamp)) — \(DateFormatting.fullDisplayString(from: last.timestamp))")
                }

                // Level breakdown
                let levelCounts = Dictionary(grouping: entries, by: \.logLevel)
                    .mapValues(\.count)
                    .sorted { $0.key < $1.key }
                if !levelCounts.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Levels")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(levelCounts, id: \.key) { level, count in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(level.color)
                                    .frame(width: 8, height: 8)
                                    .accessibilityHidden(true)
                                Text("\(level.rawValue): \(count)")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                }

                // Unique processes
                let processes = Set(entries.map(\.processName)).sorted()
                if !processes.isEmpty {
                    detailRow("Processes", processes.joined(separator: ", "))
                }

                // Unique subsystems
                let subsystems = Set(entries.compactMap { $0.subsystem.isEmpty ? nil : $0.subsystem }).sorted()
                if !subsystems.isEmpty {
                    detailRow("Subsystems", subsystems.joined(separator: ", "))
                }
            }
            .padding()
        }
    }

    private func askAISection(entries: [LogEntry]) -> some View {
        GroupBox("Ask AI") {
            HStack(spacing: 8) {
                Menu {
                    ForEach(AIProvider.allCases) { provider in
                        Button(provider.rawValue) {
                            AIPromptService.preferredProvider = provider
                            AIPromptService.askAI(about: entries, using: provider)
                        }
                    }
                } label: {
                    Label("Ask AI (\(preferredProvider.rawValue))", systemImage: "brain")
                }
                .menuStyle(.borderedButton)

                Button {
                    AIPromptService.askAI(about: entries, using: preferredProvider)
                } label: {
                    Label("Open", systemImage: "arrow.up.right.square")
                }

                Button {
                    AIPromptService.copyPromptToClipboard(for: entries)
                    showCopiedFeedback = true
                    feedbackTask?.cancel()
                    feedbackTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        if !Task.isCancelled {
                            showCopiedFeedback = false
                        }
                    }
                } label: {
                    Label(showCopiedFeedback ? "Copied!" : "Copy Prompt", systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func detailRow(_ label: String, _ value: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(color ?? .primary)
                .textSelection(.enabled)
        }
    }

    private func detailSection(_ label: String, _ value: String, isMessage: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.system(isMessage ? .body : .caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
