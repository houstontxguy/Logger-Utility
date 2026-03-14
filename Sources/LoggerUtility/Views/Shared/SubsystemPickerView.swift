import SwiftUI

struct SubsystemPickerView: View {
    @Binding var selection: String
    @State private var isCustom = false

    var body: some View {
        HStack(spacing: 4) {
            Picker("Subsystem", selection: $selection) {
                Text("All").tag("")
                Divider()
                ForEach(SubsystemPreset.all, id: \.self) { preset in
                    Text(preset).tag(preset)
                }
                Divider()
                Text("Custom...").tag("__custom__")
            }
            .labelsHidden()
            .onChange(of: selection) { newValue in
                if newValue == "__custom__" {
                    selection = ""
                    isCustom = true
                } else {
                    isCustom = false
                }
            }

            if isCustom {
                TextField("Custom subsystem", text: $selection)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
