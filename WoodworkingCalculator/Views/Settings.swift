import SwiftUI

struct Settings: View {
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey)
    private var displayInchesOnly = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey)
    private var precision = Constants.AppStorage.precisionDefault
    @AppStorage(Constants.AppStorage.assumeInchesKey)
    private var assumeInches = Constants.AppStorage.assumeInchesDefault

    private static let precisionSteps: [RationalPrecision] = [
        RationalPrecision(denominator: 1),
        RationalPrecision(denominator: 2),
        RationalPrecision(denominator: 4),
        RationalPrecision(denominator: 8),
        RationalPrecision(denominator: 16),
        RationalPrecision(denominator: 32),
        RationalPrecision(denominator: 64),
    ]

    private var sliderIndex: Double {
        Double(Self.precisionSteps.firstIndex(of: precision) ?? 0)
    }

    private func indexToPrecision(_ index: Double) -> RationalPrecision {
        let i = max(0, min(Self.precisionSteps.count - 1, Int(index.rounded())))
        return Self.precisionSteps[i]
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Precision") {
                    Text("\(precision.rational.formatted)\"")
                }
                Slider(
                    value: Binding(
                        get: { sliderIndex },
                        set: { precision = indexToPrecision($0) }
                    ),
                    in: 0...Double(Self.precisionSteps.count - 1),
                    step: 1.0,
                    label: { Text("Precision") },
                    tick: { value in
                        switch Int(value.rounded()) {
                        case 0: SliderTick(value, label: { Text("1\"") })
                        case 3: SliderTick(value, label: { Text("1/8\"") })
                        case 6: SliderTick(value, label: { Text("1/64\"") })
                        default: SliderTick(value, label: { Text("0") })
                        }
                    }
                )
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
                        Text("If no units are entered, the result is given in inches. If units are entered but cancel out, the result is a unitless decimal number.")
                    } else {
                        Text("If no units are entered, the result is a unitless decimal number.")
                    }
                    Text("Entering units is optional. Unitless numbers adopt the unit of other numbers they are combined with.")
                    Text("Long-press the feet or inches button to enter areas or volumes.")
                }
            }
        }
        .padding(.bottom)
    }
}

#Preview {
    Settings()
}
