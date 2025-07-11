import SwiftUI

struct Settings: View {
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey) private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey) private var precision: Int = Constants.AppStorage.precisionDefault
    
    var body: some View {
        Form {
            Section {
                Picker(selection: $precision, label: Text("Precision")) {
//                    Text("¹⁄₁₆").tag(16)
//                    Text("¹⁄₃₂").tag(32)
//                    Text("¹⁄₆₄").tag(64)
                    Text("1/16\"").tag(16)
                    Text("1/32\"").tag(32)
                    Text("1/64\"").tag(64)
                }
            } header: {
                Text("Calculation")
            }
            Section {
                Toggle("Show Only Inches", isOn: $displayInchesOnly)
            } header: {
                Text("Display")
            }
        }
    }
}

#Preview {
    Settings()
}
