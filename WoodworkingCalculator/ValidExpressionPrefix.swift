import Foundation

enum PreferredUnit: Equatable {
    case feet
    case inches

    var symbol: String {
        switch self {
        case .feet: "'"
        case .inches: "\""
        }
    }

    var abbreviation: String {
        switch self {
        case .feet: "ft"
        case .inches: "in"
        }
    }
}

// Exists because there are multi-character sequences that must be trimmed as an atomic unit.
// We want to make sure that callers don't try to chop single characters off the end because they
// might create something very invalid.
//
// As of this writing there are no trim rules that interact with such multi-character sequences, but
// the backspace logic which is related to this does, so I took the opportunity to move all the
// logic here instead.
enum TrimmableCharacterSet {
    case whitespaceAndFractionSlash

    internal var set: Set<Character> {
        switch self {
        case .whitespaceAndFractionSlash: Set([" ", "/"])
        }
    }
}

struct ValidExpressionPrefix: Equatable {
    let value: String

    init() {
        value = ""
    }

    init?(_ string: String) {
        guard EvaluatableCalculation.isValidPrefix(string) else {
            return nil
        }
        value = string
    }

    init(_ quantity: UsCustomaryQuantity, as preferredUnit: PreferredUnit, denominator: Int) {
        value = if quantity.dimension.value == 1 {
            formatRational(quantity.toRational(withDenominator: denominator).0, preferredUnit)
        } else {
            formatDecimal(quantity.toReal(), quantity.dimension, preferredUnit)
        }
    }

    var backspaced: ValidExpressionPrefix {
        if let match = value.firstMatch(of: /(in|ft|mm|cm|m)(\[-?[0-9]+\])?$/) {
            // FIXME: Don't like non-null assertion.
            .init(String(value.prefix(value.count - match.output.0.count)))!
        } else {
            // FIXME: Don't like non-null assertion.
            .init(value.count == 0 ? "" : String(value.prefix(value.count - 1)))!
        }
    }

    var pretty: String {
        value
            .replacing(/(in|ft|mm|cm|m)(\[(-?[0-9]+)\])?/, with: { match in
                let exponent = if let raw = match.3 {
                    Int(raw)!
                } else {
                    1
                }
                let unit = if match.1 == "in" && exponent == 1 {
                    "\""
                } else if match.1 == "ft" && exponent == 1 {
                    "'"
                } else {
                    String(match.1)
                }
                return "\(unit)\(exponent == 1 ? "" : exponent.superscript)"
            })
            .replacing(/([0-9]+)\/([0-9]*)/, with: { match in
                "\(Int(match.1)!.superscript)\u{2044}\(Int(match.2).map(\.subscript) ?? " ")"
            })
            .replacing(/([0-9]) ([0-9]|$)/, with: { match in
                "\(match.1)\u{2002}\(match.2)"
            })
    }

    func append(_ suffix: String, trimmingSuffix trimmableCharacters: TrimmableCharacterSet? = nil) -> ValidExpressionPrefix? {
        var string = value
        if let trimmableSet = trimmableCharacters?.set {
            while string.count > 0 && trimmableSet.contains(string.last!) {
                string.removeLast()
            }
        }
        return .init((string + suffix).replacing(/\ +/, with: " "))
    }
}

private func formatRational(_ rational: Rational, _ preferredUnit: PreferredUnit) -> String {
    var n = abs(rational.num)
    let d = abs(rational.den)

    var parts: [String] = []

    if d == 1 {
        if n >= 12 && preferredUnit == .feet {
            parts.append("\(n / 12)ft")
            n = n % 12
        }

        if parts.isEmpty || n > 0 {
            parts.append("\(n)in")
        }
    } else {
        if n >= 12 * d && preferredUnit == .feet {
            parts.append("\(n / (12 * d))ft")
            n = n % (12 * d)
        }

        if n > d {
            parts.append("\(n / d) \(UncheckedRational(n % d, d))in")
        } else {
            parts.append("\(UncheckedRational(n, d))in")
        }
    }

    return "\(rational.signum() == -1 ? "-" : "")\(parts.joined(separator: " "))"
}

private func formatDecimal(_ real: Double, _ dimension: Dimension, _ preferredUnit: PreferredUnit) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = false
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    formatter.roundingMode = .halfUp
    
    // Convert from inches to feet for higher dimensions when preferred unit is feet
    let convertedValue = if preferredUnit == .feet && dimension.value > 1 {
        real / pow(12.0, Double(dimension.value))
    } else {
        real
    }
    
    let formattedString = formatter.string(from: NSNumber(value: convertedValue)) ?? convertedValue.formatted()
    return switch dimension.value {
    case 0: formattedString
    case 1: "\(formattedString)\(preferredUnit.symbol)"
    default: "\(formattedString)\(preferredUnit.abbreviation)[\(dimension.value)]"
    }
}

