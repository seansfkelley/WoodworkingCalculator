import Foundation
import SwiftUI

struct Constants {
    struct AppStorage {
        static let displayInchesOnlyKey = "displayInchesOnly"
        static let displayInchesOnlyDefault = false
        
        static let precisionKey = "precision"
        static let precisionDefault = RationalPrecision(denominator: 32)

        static let assumeInchesKey = "assumeInches"
        static let assumeInchesDefault = true

        static let themeKey = "theme"
        static let themeDefault: Theme = .system
    }

    enum Theme: String {
        case light, dark, system

        var colorScheme: ColorScheme? {
            switch self {
            case .dark: .dark
            case .light: .light
            case .system: nil
            }
        }
    }

    struct DecimalPrecision {
        static let standard = 3
        static let roundingError = 4
        static let unitless = 9
    }
}
