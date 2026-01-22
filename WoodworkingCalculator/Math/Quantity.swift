// In inches.
enum Quantity: Equatable, CustomStringConvertible {
    case rational(Rational, Dimension)
    case real(Double, Dimension)

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

    var dimension: Dimension {
        switch self {
        case .rational(_, let dimension): dimension
        case .real(_, let dimension): dimension
        }
    }

    var meters: Double? {
        if dimension != .unitless {
            // Decimal ratio is exact, by definition of the US customary system: 1" = 25.4mm.
            // https://en.wikipedia.org/wiki/United_States_customary_units#International_units
            toReal() * (0.0254 ^^ dimension)
        } else {
            nil
        }
    }

    func toReal() -> Double {
        switch self {
        case .rational(let value, _): Double(value)
        case .real(let value, _): value
        }
    }

    func toRational(precision: RationalPrecision) -> (Rational, Double) {
        switch self {
        case .rational(let value, _): value.roundedTo(precision: precision)
        case .real(let value, _): value.toNearestRational(of: precision)
        }
    }

    func formatted(as unit: UsCustomaryUnit, to precision: RationalPrecision, toDecimalPrecision digits: Int) -> (String, (Double, RationalPrecision, Dimension)?) {
        let dimensionallyAdjustedPrecision = RationalPrecision(denominator: precision.denominator ^^ dimension)
        let (rounded, inaccuracy) = toRational(precision: dimensionallyAdjustedPrecision)
        return if dimension == .unitless {
            (toReal().formatted(), nil) // TODO: better formatting
        } else if dimension == .length {
            (formatOneDimensionalRational(inches: rounded, as: unit), (inaccuracy, dimensionallyAdjustedPrecision, dimension))
        } else {
            (formatDecimal(inches: Double(rounded), of: dimension, as: unit, to: digits), (inaccuracy, dimensionallyAdjustedPrecision, dimension))
        }
    }
}
