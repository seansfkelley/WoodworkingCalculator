// In inches.
enum Quantity: Equatable, CustomStringConvertible {
    case rational(Rational, Dimension)
    case real(Double, Dimension)

    struct RoundingError: Equatable {
        let error: Double
        let oneDimensionalPrecision: RationalPrecision
        let dimension: Dimension

        var dimensionallyAdjustedPrecision: RationalPrecision {
            .init(denominator: oneDimensionalPrecision.denominator ^^ dimension)
        }
    }

    struct FormattingOptions: Equatable {
        let unit: UsCustomaryUnit
        let roundingUnitsTo: RationalPrecision
        let maxUnitDecimalDigits: Int
        let maxUnitlessDecimalDigits: Int

        init(_ unit: UsCustomaryUnit, _ roundingUnitsTo: RationalPrecision, _ maxUnitDecimalDigits: Int, _ maxUnitlessDecimalDigits: Int) {
            self.unit = unit
            self.roundingUnitsTo = roundingUnitsTo
            self.maxUnitDecimalDigits = maxUnitDecimalDigits
            self.maxUnitlessDecimalDigits = maxUnitlessDecimalDigits
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

    func withDimension(_ dimension: Dimension) -> Quantity {
        switch self {
        case .rational(let value, _): .rational(value, dimension)
        case .real(let value, _): .real(value, dimension)
        }
    }

    func formatted(with options: FormattingOptions) -> (String, RoundingError?) {
        guard dimension != .unitless else {
            return (toReal().formatAsDecimal(toPlaces: options.maxUnitlessDecimalDigits), nil)
        }

        let (rounded, error) = toRational(precision: RationalPrecision(denominator: options.roundingUnitsTo.denominator ^^ dimension))
        let roundingError: RoundingError? = error.isZero
            ? nil
            : RoundingError(error: error, oneDimensionalPrecision: options.roundingUnitsTo, dimension: dimension)
        return if dimension == .length {
            (
                rounded.formatInches(as: options.unit),
                roundingError,
            )
        } else {
            (
                Double(rounded).formatInches(as: options.unit, of: dimension, toPlaces: options.maxUnitDecimalDigits),
                roundingError,
            )
        }
    }
}
