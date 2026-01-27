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

    struct DecimalPrecision {
        static let standard = 3
        static let roundingError = 4
        static let unitless = 9
    }
}
