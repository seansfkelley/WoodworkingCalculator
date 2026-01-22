// In inches.
enum UsCustomaryQuantity: Equatable, CustomStringConvertible {
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
            return "\(rational)in\(dimension)"
        case .real(let real, let dimension):
            let rounded = (real * 1_000_000).rounded() / 1_000_000
            let prefix = rounded == real ? "" : "~"
            return "\(prefix)\(rounded)in\(dimension)"
        }
    }

    func toReal() -> Double {
        switch self {
        case .rational(let value, _): Double(value)
        case .real(let value, _): value
        }
    }

    func toRational(withDenominator denominator: Int) -> (Rational, Double?) {
        switch self {
        case .rational(let value, _): value.roundedToDenominator(denominator)
        case .real(let value, _): value.toNearestRational(withDenominator: denominator)
        }
    }
}
