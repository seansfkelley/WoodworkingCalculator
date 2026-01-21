import Foundation

enum UsCustomaryPrecision: Equatable {
    case feet
    case inches
}

func formatAsUsCustomary(_ rational: Rational, _ dimension: Dimension, _ precision: UsCustomaryPrecision = .feet) -> String {
    var n = abs(rational.num)
    let d = abs(rational.den)
    
    var parts: [String] = []
    
    if d == 1 {
        if n >= 12 && precision == .feet {
            parts.append("\(n / 12)'")
            n = n % 12;
        }
        
        if parts.isEmpty || n > 0 {
            parts.append("\(n)\"")
        }
    } else {
        if n >= 12 * d && precision == .feet {
            parts.append("\(n / (12 * d))'");
            n = n % (12 * d);
        }
        
        if n > d {
            parts.append("\(n / d) \(UncheckedRational(n % d, d))\"")
        } else {
            parts.append("\(UncheckedRational(n, d))\"")
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

extension Rational {
    var fancyDescription: String {
        return den == 1 ? "\(num)" : "\(num.numerator)⁄\(den.denominator)"
    }
}
