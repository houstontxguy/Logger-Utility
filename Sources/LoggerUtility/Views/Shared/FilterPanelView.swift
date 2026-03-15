import SwiftUI

struct FilterPanelView: View {
    @ObservedObject var viewModel: FilterViewModel
    var discoveredSubsystems: [(name: String, count: Int)] = []
    var onApply: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Filters")
                    .font(.headline)

                Group {
                    labeledField("Process") {
                        TextField("Process name", text: $viewModel.filter.process)
                            .textFieldStyle(.roundedBorder)
                    }

                    labeledField("Subsystem") {
                        SubsystemPickerView(
                            selection: $viewModel.filter.subsystem,
                            discoveredSubsystems: discoveredSubsystems
                        )
                    }

                    labeledField("Category") {
                        TextField("Category", text: $viewModel.filter.category)
                            .textFieldStyle(.roundedBorder)
                    }

                    labeledField("Sender") {
                        TextField("Sender", text: $viewModel.filter.sender)
                            .textFieldStyle(.roundedBorder)
                    }

                    labeledField("Message Search") {
                        TextField("Search message text", text: $viewModel.filter.messageSearch)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Divider()

                LogLevelPickerView(selectedLevels: $viewModel.filter.selectedLevels)

                Divider()

                PredicateBuilderView(
                    clauses: $viewModel.filter.predicateClauses,
                    joinOperator: $viewModel.filter.joinOperator,
                    onAdd: { viewModel.addClause() },
                    onRemove: { viewModel.removeClause(id: $0) }
                )

                Divider()

                labeledField("Raw Predicate (overrides above)") {
                    TextField("e.g. subsystem == \"com.apple.bluetooth\"", text: $viewModel.filter.rawPredicate)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Include Info messages (--info)", isOn: $viewModel.filter.includeInfo)
                    Toggle("Include Debug messages (--debug)", isOn: $viewModel.filter.includeDebug)
                    Toggle("Include source info (--source)", isOn: $viewModel.filter.includeSource)
                }

                Divider()

                HStack {
                    Button("Reset") {
                        viewModel.reset()
                    }
                    Spacer()
                    Button("Apply") {
                        onApply()
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(minWidth: 280, idealWidth: 300)
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }
}
