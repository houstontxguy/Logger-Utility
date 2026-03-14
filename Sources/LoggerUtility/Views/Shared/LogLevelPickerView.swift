import SwiftUI

struct LogLevelPickerView: View {
    @Binding var selectedLevels: Set<LogLevel>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log Levels")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
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
                        }
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
    }
}
