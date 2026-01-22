import Foundation

enum PreferredUnit: Equatable {
    case feet
    case inches
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

    init(_ quantity: Quantity, as preferredUnit: PreferredUnit, precision: Int) {
        value = if quantity.dimension.value == 0 {
            formatDecimal(quantity.toReal(), quantity.dimension, preferredUnit)
        } else {
            formatRational(quantity.toRational(withPrecision: precision).0, quantity.dimension, preferredUnit)
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

private func formatRational(_ rational: Rational, _ dimension: Dimension, _ preferredUnit: PreferredUnit) -> String {
    var n = abs(rational.num)
    let d = abs(rational.den)

    if dimension.value == 0 {
        return rational.den == 1
            ? "\(rational.signum() == -1 ? "-" : "")\(n)"
            : "\(rational.signum() == -1 ? "-" : "")\(n)/\(d)"
    }

    let feetUnit = "ft[\(dimension.value)]"
    let inchUnit = "in[\(dimension.value)]"

    // This is shit, and should stay in integers the whole time. It also doesn't handle negatives
    // properly at all -- what do we want to do about that?
    let conversionFactor = Int(pow(12.0, Double(dimension.value)))

    var parts: [String] = []

    if d == 1 {
        if n >= conversionFactor && preferredUnit == .feet {
            parts.append("\(n / conversionFactor)\(feetUnit)")
            n = n % conversionFactor
        }

        if parts.isEmpty || n > 0 {
            parts.append("\(n)\(inchUnit)")
        }
    } else {
        if n >= conversionFactor * d && preferredUnit == .feet {
            parts.append("\(n / (conversionFactor * d))\(feetUnit)")
            n = n % (conversionFactor * d)
        }

        if n > d {
            parts.append("\(n / d) \(UncheckedRational(n % d, d))\(inchUnit)")
        } else {
            parts.append("\(UncheckedRational(n, d))\(inchUnit)")
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
    return formatter.string(from: NSNumber(value: real)) ?? real.formatted()
}

