enum Inches: Equatable, CustomStringConvertible {
    case rational(Rational, Dimension)
    case real(Double, Dimension)

    var dimension: Dimension {
        switch self {
        case .rational(_, let dimension): dimension
        case .real(_, let dimension): dimension
        }
    }

    var description: String {
        switch self {
        case .rational(let rational, let dimension):
            return "\(rational)\(dimension.formatted(withUnit: "in"))"
        case .real(let real, let dimension):
            let rounded = (real * 1_000_000).rounded() / 1_000_000
            let prefix = rounded == real ? "" : "~"
            return "\(prefix)\(rounded)\(dimension.formatted(withUnit: "in"))"
        }
    }

    func toReal() -> Double {
        switch self {
        case .rational(let value, _): Double(value)
        case .real(let value, _): value
        }
    }

    func toRational(withDenominator denominator: Int, epsilon: Double) -> (Rational, Double?) {
        switch self {
        case .rational(let value, _): value.roundedToDenominator(denominator, epsilon: epsilon)
        case .real(let value, _): value.toNearestRational(withDenominator: denominator, epsilon: epsilon)
        }
    }

    func formatted(as unit: UsCustomaryUnit, withDenominator denominator: Int, toDecimalPrecision digits: Int, epsilon: Double) -> String {
        let rounded = toRational(withDenominator: denominator, epsilon: epsilon).0
        return if dimension.value == 1 {
            formatOneDimensionalRational(inches: rounded, as: unit)
        } else {
            formatDecimal(inches: Double(rounded), of: dimension, as: unit, to: digits)
        }
    }
}
