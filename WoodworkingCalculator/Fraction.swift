// 1/64th ~ 0.015, so quite a bit larger than a thou, meaning this is very conservative about fractionalizing things.
let EPSILON = 0.001;
let HIGHEST_PRECISION: Int = 64;

struct Fraction: Equatable {
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
        // TODO: make sure precision is a power of 2
        if self.den <= precision {
            return (self, nil)
        } else {
            return Double(self).toNearestFraction(withPrecision: precision)
        }
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

extension Fraction: CustomStringConvertible {
    var description: String {
        let n = self.num
        let d = self.den
        if d == 1 {
            if n > 12 {
                return "\(n / 12)' \(n % 12)\""
            } else {
                return "\(n)\""
            }
        } else {
            if n > 12 * d {
                return "\(n / (12 * d))' \(Fraction(n % (12 * d), d))"
            } else if n > d {
                return "\(n / d)-\(n % d)/\(d)\""
            } else {
                return "\(n)/\(d)\""
            }
        }
    }
}

extension Double {
    init(_ fraction: Fraction) {
        self = Double(fraction.num) / Double(fraction.den)
    }
    
    func toNearestFraction(withPrecision: Int) -> (Fraction, Double?) {
        // TODO: make sure precision is a power of 2
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
