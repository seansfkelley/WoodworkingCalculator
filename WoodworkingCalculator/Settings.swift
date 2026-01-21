import SwiftUI

struct Settings: View {
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey) private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey) private var precision: Int = Constants.AppStorage.precisionDefault
    
    var body: some View {
        Form {
            Section {
                Picker(selection: $precision, label: Text("Precision")) {
                    Text("1\"").tag(1)
                    Text("1/2\"").tag(2)
                    Text("1/4\"").tag(4)
                    Text("1/8\"").tag(8)
                    Text("1/16\"").tag(16)
                    Text("1/32\"").tag(32)
                    Text("1/64\"").tag(64)
                }
            } header: {
                Text("Calculation")
            }
            Section {
                Picker(selection: $displayInchesOnly, label: Text("Result Format")) {
                    Text("Inches").tag(true)
                    Text("Feet and Inches").tag(false)
                }
            } header: {
                Text("Display")
            }
        }
    }
}

#Preview {
    Settings()
}
