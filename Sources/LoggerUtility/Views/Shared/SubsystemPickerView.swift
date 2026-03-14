import SwiftUI

struct SubsystemPickerView: View {
    @Binding var selection: String
    var discoveredSubsystems: [(name: String, count: Int)] = []
    @State private var isCustom = false
    @State private var pickerSelection: String = ""

    var body: some View {
        HStack(spacing: 4) {
            if isCustom {
                TextField("Custom subsystem", text: $selection)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    isCustom = false
                    selection = ""
                    pickerSelection = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Picker("Subsystem", selection: $pickerSelection) {
                    Text("All").tag("")

                    if !discoveredSubsystems.isEmpty {
                        Divider()
                        Section("From Results") {
                            ForEach(discoveredSubsystems, id: \.name) { item in
                                Text("\(item.name) (\(item.count))")
                                    .tag(item.name)
                            }
                        }
                    }

                    Divider()
                    Section("Common") {
                        ForEach(presetsNotInDiscovered, id: \.self) { preset in
                            Text(preset).tag(preset)
                        }
                    }

                    Divider()
                    Text("Custom...").tag("__custom__")
                }
                .labelsHidden()
                .onChange(of: pickerSelection) { newValue in
                    if newValue == "__custom__" {
                        isCustom = true
                        selection = ""
                        pickerSelection = ""
                    } else {
                        selection = newValue
                    }
                }
                .onAppear {
                    pickerSelection = selection
                }
            }
        }
    }

    /// Apple presets that aren't already in the discovered list
    private var presetsNotInDiscovered: [String] {
        let discoveredNames = Set(discoveredSubsystems.map(\.name))
        return SubsystemPreset.all.filter { !discoveredNames.contains($0) }
    }
}
