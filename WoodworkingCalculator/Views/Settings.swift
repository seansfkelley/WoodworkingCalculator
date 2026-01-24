import SwiftUI

struct Settings: View {
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey)
    private var displayInchesOnly = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey)
    private var precision = Constants.AppStorage.precisionDefault
    @AppStorage(Constants.AppStorage.assumeInchesKey)
    private var assumeInches = Constants.AppStorage.assumeInchesDefault

    var body: some View {
        Form {
            Section {
                Picker(selection: $precision, label: Text("Precision")) {
                    Text("1\"").tag(RationalPrecision(denominator: 1))
                    Text("1/2\"").tag(RationalPrecision(denominator: 2))
                    Text("1/4\"").tag(RationalPrecision(denominator: 4))
                    Text("1/8\"").tag(RationalPrecision(denominator: 8))
                    Text("1/16\"").tag(RationalPrecision(denominator: 16))
                    Text("1/32\"").tag(RationalPrecision(denominator: 32))
                    Text("1/64\"").tag(RationalPrecision(denominator: 64))
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Results with units will be rounded to the nearest \(precision.rational.formatted)\". Areas and volumes are rounded to the corresponding square or cube.")
                    Text("Unitless results are not rounded.")
                }
            }

            Section {
                Picker(selection: $displayInchesOnly, label: Text("Result Format")) {
                    Text("Inches").tag(true)
                    Text("Feet and Inches").tag(false)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Results for lengths will display as \(displayInchesOnly ? "inches only" : "feet and inches"). Area and volume results will be decimal \(displayInchesOnly ? "inches" : "feet").")
                    Text("Unitless results are always decimals.")
                }
            }

            Section {
                Toggle("Assume Inches", isOn: $assumeInches)
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if assumeInches {
                        Text("If no units are entered, the result is assumed to be inches. If units are entered but cancel out, the result is a unitless decimal number.")
                    } else {
                        Text("If no units are entered, the result is a unitless decimal number.")
                    }
                    Text("Entering units is optional. Unitless numbers adopt the unit of other numbers they are combined with.")
                    Text("Long-press the unit buttons to enter areas or volumes.")
                }
            }
        }
        .padding(.bottom)
    }
}

#Preview {
    Settings()
}
