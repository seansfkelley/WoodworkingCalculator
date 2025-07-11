import SwiftUI

struct Settings: View {
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey) private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    
    var body: some View {
        Form {
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
