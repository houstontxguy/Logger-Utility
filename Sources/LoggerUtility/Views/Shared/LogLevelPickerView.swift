import SwiftUI

struct LogLevelPickerView: View {
    @Binding var selectedLevels: Set<LogLevel>

    private let columns = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(), alignment: .leading),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log Levels")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                ForEach(LogLevel.allCases) { level in
                    Toggle(isOn: Binding(
                        get: { selectedLevels.contains(level) },
                        set: { isOn in
                            if isOn {
                                selectedLevels.insert(level)
                            } else {
                                selectedLevels.remove(level)
                            }
                        }
                    )) {
                        HStack(spacing: 4) {
                            ColorDot(color: level.color)
                            Text(level.rawValue)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
    }
}
