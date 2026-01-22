import Foundation

struct RationalPrecision: Hashable, RawRepresentable {
    typealias RawValue = Int

    let denominator: UInt

    init(denominator: UInt) {
        self.denominator = denominator
    }

    init?(rawValue: Int) {
        self.denominator = UInt(rawValue)
    }
    
    var rawValue: Int {
        Int(denominator)
    }

    var rational: Rational {
        UncheckedRational(1, Int(denominator)).unsafe
    }
}
