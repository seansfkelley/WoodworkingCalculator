import Foundation

struct Constants {
    struct AppStorage {
        static let displayInchesOnlyKey = "displayInchesOnly"
        static let displayInchesOnlyDefault = false
        
        static let precisionKey = "precision"
        static let precisionDefault = RationalPrecision(denominator: 32)

        static let assumeInchesKey = "assumeInches"
        static let assumeInchesDefault = true
    }

    static let decimalDigitsOfPrecision = 3
    static let decimalDigitsOfPrecisionExtended = 6
    static let decimalDigitsOfPrecisionUnitless = 9
}
