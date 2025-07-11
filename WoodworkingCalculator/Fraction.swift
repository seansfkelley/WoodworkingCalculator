// 1/64th ~ 0.015, so quite a bit larger than a thou, meaning this is very conservative about fractionalizing things.
let EPSILON = 0.001;
let HIGHEST_PRECISION: Int = 64;

struct Fraction: Equatable, Hashable, CustomStringConvertible {
    let num: Int
    let den: Int
    
    init(_ num: Int, _ den: Int) {
        self.num = num
        self.den = den
    }
    
    var reduced: Fraction {
        let divisor = gcd(self.num, self.den)
        return Fraction(self.num / divisor, self.den / divisor)
    }
    
    func roundedToPrecision(_ precision: Int) -> (Fraction, Double?) {
        if self.den <= precision && self.den % precision == 0 {
            return (self, nil)
        } else {
            return Double(self).toNearestFraction(withPrecision: precision)
        }
    }
    
    var description: String {
        return "\(asSubscript(self.num))\u{2044}\(asSubscript(self.den))"
    }
    
    static func == (left: Fraction, right: Fraction) -> Bool {
        let lreduced = left.reduced
        let rreduced = right.reduced
        return lreduced.num == rreduced.num && lreduced.den == rreduced.den
    }
    
    static func + (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.den + right.num * left.den, left.den * right.den).reduced
    }
    
    static func - (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.den - right.num * left.den, left.den * right.den).reduced
    }
    
    static func * (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.num, left.den * right.den).reduced
    }
    
    static func / (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.den, left.den * right.num).reduced
    }
}

private func gcd(_ a: Int, _ b: Int) -> Int {
  let r = a % b
  if r != 0 {
    return gcd(b, r)
  } else {
    return b
  }
}

let unicodeSuperscript: [Character: Character] = [
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
let unicodeSubscript: [Character: Character] = [
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

func asSuperscript(_ int: Int) -> String {
    return String(int).replacing(#/[0-9]/#, with: { match in [unicodeSuperscript[match.output.first!]!] })
}

func asSubscript(_ int: Int) -> String {
    return String(int).replacing(#/[0-9]/#, with: { match in [unicodeSubscript[match.output.first!]!] })
}

extension Double {
    init(_ fraction: Fraction) {
        self = Double(fraction.num) / Double(fraction.den)
    }
    
    func toNearestFraction(withPrecision: Int) -> (Fraction, Double?) {
        let upperFraction = Fraction(Int((self * Double(withPrecision)).rounded(.up)), withPrecision).reduced
        let lowerFraction = Fraction(Int((self * Double(withPrecision)).rounded(.down)), withPrecision).reduced
        
        let upperError = Double(upperFraction) - self
        let lowerError = self - Double(lowerFraction)
        
        if upperError <= EPSILON {
            return (upperFraction, nil)
        } else if lowerError <= EPSILON {
            return (lowerFraction, nil)
        } else if upperError < lowerError {
            return (upperFraction, upperError)
        } else {
            return (lowerFraction, -lowerError)
        }
    }
}
