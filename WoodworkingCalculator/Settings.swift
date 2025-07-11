import SwiftUI

struct Settings: View {
    @AppStorage(Constants.AppStorageKey.displayFeet) private var displayFeet: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Show Only Inches", isOn: $displayFeet)
            } header: {
                Text("Display")
            }
        }
    }
}

#Preview {
    Settings()
}
