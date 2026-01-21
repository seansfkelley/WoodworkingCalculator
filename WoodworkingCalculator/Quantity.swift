enum Quantity: Equatable {
    case rational(Rational, Dimension)
    case real(Double, Dimension)

    var dimension: Dimension {
        switch self {
        case .rational(_, let dimension): dimension
        case .real(_, let dimension): dimension
        }
    }

    func toReal() -> Double {
        switch self {
        case .rational(let value, _): Double(value)
        case .real(let value, _): value
        }
    }

    func toRational(withPrecision precision: Int) -> (Rational, Double?) {
        switch self {
        case .rational(let value, _): (value, nil)
        case .real(let value, _): value.toNearestRational(withDenominator: precision)
        }
    }
}
