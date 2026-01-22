import Foundation

struct Constants {
    struct AppStorage {
        static let displayInchesOnlyKey = "displayInchesOnly"
        static let displayInchesOnlyDefault = false
        
        static let precisionKey = "precision"
        static let precisionDefault = 32
    }

    static let decimalDigitsOfPrecision = 3
    static var epsilon: Double { pow(0.1, Double(decimalDigitsOfPrecision)) }
}
