import SwiftUI

struct StreamStatusBar: View {
    @ObservedObject var viewModel: StreamViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Connection status
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
            }

            Divider()
                .frame(height: 12)

            Text("\(viewModel.entryCount) entries")
                .font(.caption)
                .foregroundColor(.secondary)

            if viewModel.isRunning {
                Divider()
                    .frame(height: 12)

                Text("\(String(format: "%.0f", viewModel.entriesPerSecond)) entries/sec")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.isPaused {
                Divider()
                    .frame(height: 12)

                Text("PAUSED")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }

            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var statusColor: Color {
        if viewModel.isRunning {
            return viewModel.isPaused ? .orange : .green
        }
        return .gray
    }

    private var statusText: String {
        if viewModel.isRunning {
            return viewModel.isPaused ? "Paused" : "Streaming"
        }
        return "Stopped"
    }
}
