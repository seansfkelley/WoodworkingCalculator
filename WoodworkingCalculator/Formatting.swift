enum UsCustomaryPrecision: Equatable {
    case feet
    case inches
}

func formatAsUsCustomary(_ rational: Rational, _ precision: UsCustomaryPrecision = .feet) -> String {
    var n = rational.reduced.num
    let d = rational.reduced.den
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
            parts.append("\(n / d) \(Rational(n % d, d))\"")
        } else {
            parts.append("\(Rational(n, d))\"")
        }
    }
    
    return parts.joined(separator: " ")
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

private func asSuperscript(_ int: Int) -> String {
    return String(int).replacing(#/[0-9]/#, with: { match in [unicodeSuperscript[match.output.first!]!] })
}

private func asSubscript(_ int: Int) -> String {
    return String(int).replacing(#/[0-9]/#, with: { match in [unicodeSubscript[match.output.first!]!] })
}

extension Rational {
    var fancyDescription: String {
        let r = reduced
        return r.den == 1 ? "\(r.num)" : "\(asSuperscript(r.num))⁄\(asSubscript(r.den))"
    }
}
