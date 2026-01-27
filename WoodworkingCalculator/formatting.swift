import Foundation

enum UsCustomaryUnit: Equatable {
    case feet
    case inches

    var abbreviation: String {
        switch self {
        case .feet: "ft"
        case .inches: "in"
        }
    }
}

extension Rational {
    func formatInches(as unit: UsCustomaryUnit) -> String {
        var n = abs(num)
        let d = abs(den)

        var parts: [String] = []

        if d == 1 {
            if n >= 12 && unit == .feet {
                parts.append("\(n / 12)\(UsCustomaryUnit.feet.abbreviation)")
                n = n % 12
            }

            if parts.isEmpty || n > 0 {
                parts.append("\(n)\(UsCustomaryUnit.inches.abbreviation)")
            }
        } else {
            if n >= 12 * d && unit == .feet {
                parts.append("\(n / (12 * d))\(UsCustomaryUnit.feet.abbreviation)")
                n = n % (12 * d)
            }

            if n > d {
                parts.append("\(n / d) \(UncheckedRational(n % d, d))\(UsCustomaryUnit.inches.abbreviation)")
            } else {
                parts.append("\(UncheckedRational(n, d))\(UsCustomaryUnit.inches.abbreviation)")
            }
        }

        return "\(signum() == -1 ? "-" : "")\(parts.joined(separator: " "))"
    }
}

extension Double {
    func formatAsDecimal(toPlaces precision: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: self)) ?? self.formatted()
    }

    func formatInches(as unit: UsCustomaryUnit, of dimension: Dimension, toPlaces precision: Int) -> String {
        let convertedValue = if unit == .feet && dimension.value > 0 {
            self / pow(12.0, Double(dimension.value))
        } else {
            self
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision
        formatter.roundingMode = .halfUp

        let formattedString = formatter.string(from: NSNumber(value: convertedValue)) ?? convertedValue.formatted()
        return switch dimension {
        case .unitless: formattedString
        case .length: "\(formattedString)\(unit.abbreviation)"
        default: "\(formattedString)\(dimension.formatted(withUnit: unit.abbreviation))"
        }
    }
}

extension String {
    var withPrettyNumbers: String {
        self
            // If modifying this, modify ValidExpressionPrefix/Dimension.formatted.
            // (I could not think of a way to couple them together at compile time.)
            .replacing(/(in|ft|mm|cm|m)(\[(-?[0-9]+)\])?/, with: { match in
                let exponent = if let raw = match.3 {
                    Int(raw)!
                } else {
                    1
                }
                let unit = if exponent == 0 {
                    ""
                } else if match.1 == "in" && exponent == 1 {
                    "\""
                } else if match.1 == "ft" && exponent == 1 {
                    "'"
                } else {
                    String(match.1)
                }
                return "\(unit)\(exponent == 1 ? "" : exponent.superscript)"
            })
            .replacing(/([0-9]) ([0-9]|$)/, with: { match in
                "\(match.1)\u{2002}\(match.2)"
            })
            .replacing(/([0-9]+)\/([0-9]*)/, with: { match in
                "\(Int(match.1)!.superscript)\u{2044}\(Int(match.2).map(\.subscript) ?? " ")"
            })
    }
}
