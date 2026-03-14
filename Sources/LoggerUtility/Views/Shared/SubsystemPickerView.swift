import SwiftUI

struct SubsystemPickerView: View {
    @Binding var selection: String
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
                    Divider()
                    ForEach(SubsystemPreset.all, id: \.self) { preset in
                        Text(preset).tag(preset)
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
}
