import Foundation

struct RationalPrecision: Hashable, RawRepresentable {
    let denominator: Int

    init(denominator: Int) {
        self.denominator = denominator
    }

    init?(rawValue: Int) {
        self.denominator = rawValue
    }
    
    var rawValue: Int {
        denominator
    }
}
