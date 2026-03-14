import SwiftUI

struct QueryStatusBar: View {
    @ObservedObject var viewModel: HistoricalViewModel

    var body: some View {
        HStack(spacing: 16) {
            if viewModel.isQuerying {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Querying...")
                        .font(.caption)
                }
            } else {
                Text("\(viewModel.resultCount) results")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.queryDuration > 0 && !viewModel.isQuerying {
                Divider()
                    .frame(height: 12)

                Text(String(format: "%.2fs", viewModel.queryDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
}
