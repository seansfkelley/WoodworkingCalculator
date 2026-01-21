import Foundation

enum UsCustomaryPrecision: Equatable {
    case feet
    case inches
}

func formatAsUsCustomary(_ rational: Rational, _ dimension: Dimension, _ precision: UsCustomaryPrecision = .feet) -> String {
    if dimension.value == 0 {
        return rational.den == 1
            ? "\(rational.signum() == -1 ? "-" : "")\(rational.num)"
            : "\(rational.signum() == -1 ? "-" : "")\(rational.num)/\(rational.den)"
    }
    
    let feetUnit = dimension.value == 1 ? "'" : "ft\(dimension.value.numerator)"
    let inchUnit = dimension.value == 1 ? "\"" : "in\(dimension.value.numerator)"

    var n = abs(rational.num)
    let d = abs(rational.den)

    // This is shit, and should stay in integers the whole time. It also doesn't handle negatives
    // properly at all -- what do we want to do about that?
    let conversionFactor = Int(pow(12.0, Double(dimension.value)))
    
    var parts: [String] = []
    
    if d == 1 {
        if n >= conversionFactor && precision == .feet {
            parts.append("\(n / conversionFactor)\(feetUnit)")
            n = n % conversionFactor
        }
        
        if parts.isEmpty || n > 0 {
            parts.append("\(n)\(inchUnit)")
        }
    } else {
        if n >= conversionFactor * d && precision == .feet {
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

func formatMetric(_ number: Double, precision: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = false
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = precision
    formatter.roundingMode = .halfUp
    return formatter.string(from: NSNumber(value: number)) ?? number.formatted()
}

private let unicodeSuperscript: [Character: Character] = [
    "0": "⁰",
    "1": "¹",
    "2": "²",
    "3": "³",
    "4": "⁴",
    "5": "⁵",
    "6": "⁶",
    "7": "⁷",
    "8": "⁸",
    "9": "⁹",
    "-": "⁻",
]

private let unicodeSubscript: [Character: Character] = [
    "0": "₀",
    "1": "₁",
    "2": "₂",
    "3": "₃",
    "4": "₄",
    "5": "₅",
    "6": "₆",
    "7": "₇",
    "8": "₈",
    "9": "₉",
    "-": "₋",
]

extension Int {
    var numerator: String {
        String(self).replacing(#/[0-9\-]/#, with: { match in [unicodeSuperscript[match.output.first!]!] })
    }
    
    var denominator: String {
        String(self).replacing(#/[0-9\-]/#, with: { match in [unicodeSubscript[match.output.first!]!] })
    }
}
