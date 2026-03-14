import SwiftUI

struct PredicateBuilderView: View {
    @Binding var clauses: [PredicateClause]
    @Binding var joinOperator: PredicateJoinOperator
    var onAdd: () -> Void
    var onRemove: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Predicate Clauses")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Join", selection: $joinOperator) {
                    ForEach(PredicateJoinOperator.allCases) { op in
                        Text(op.rawValue).tag(op)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            ForEach($clauses) { $clause in
                HStack(spacing: 4) {
                    Picker("Field", selection: $clause.field) {
                        ForEach(PredicateField.allCases) { field in
                            Text(field.displayName).tag(field)
                        }
                    }
                    .frame(width: 130)
                    .labelsHidden()

                    Picker("Operator", selection: $clause.op) {
                        ForEach(PredicateOperator.allCases) { op in
                            Text(op.displayName).tag(op)
                        }
                    }
                    .frame(width: 100)
                    .labelsHidden()

                    TextField("Value", text: $clause.value)
                        .textFieldStyle(.roundedBorder)

                    Button(action: { onRemove(clause.id) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: onAdd) {
                Label("Add Clause", systemImage: "plus.circle")
            }
            .buttonStyle(.plain)
        }
    }
}
