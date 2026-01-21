import Foundation

enum UsCustomaryPrecision: Equatable {
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

func formatAsUsCustomary(_ rational: Rational, _ dimension: Dimension, _ precision: UsCustomaryPrecision = .feet) -> String {
    let unit: String

    switch dimension.value {
    case 0:
        return rational.den == 1 ? "\(rational.num)" : "\(rational.num)/\(rational.den)"
    case 1:
        unit = precision.symbol
    case 2:
        unit = "sq \(precision.abbreviation)"
    case 3:
        unit = "cu \(precision.abbreviation)"
    default:
        unit = "\(precision.abbreviation)^\(dimension.value)"
    }

    var n = abs(rational.num)
    let d = abs(rational.den)
    
    var parts: [String] = []
    
    if d == 1 {
        if n >= 12 && precision == .feet {
            parts.append("\(n / 12)\(unit)")
            n = n % 12;
        }
        
        if parts.isEmpty || n > 0 {
            parts.append("\(n)\(unit)")
        }
    } else {
        if n >= 12 * d && precision == .feet {
            parts.append("\(n / (12 * d))\(unit)");
            n = n % (12 * d);
        }
        
        if n > d {
            parts.append("\(n / d) \(UncheckedRational(n % d, d))\(unit)")
        } else {
            parts.append("\(UncheckedRational(n, d))\(unit)")
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
]

extension Int {
    var numerator: String {
        return String(self).replacing(#/[0-9]/#, with: { match in [unicodeSuperscript[match.output.first!]!] })
    }
    
    var denominator: String {
        return String(self).replacing(#/[0-9]/#, with: { match in [unicodeSubscript[match.output.first!]!] })
    }
}
