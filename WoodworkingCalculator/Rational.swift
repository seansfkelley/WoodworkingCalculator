struct Rational: Equatable, Hashable, CustomStringConvertible {
    let num: Int
    let den: Int
    
    init(_ num: Int, _ den: Int) {
        self.num = num
        self.den = den
    }
    
    var reduced: Rational {
        let divisor = gcd(self.num, self.den)
        return Rational(self.num / divisor, self.den / divisor)
    }
    
    func roundedToPrecision(_ precision: Int) -> (Rational, Double?) {
        if self.den <= precision && self.den % precision == 0 {
            return (self, nil)
        } else {
            return Double(self).toNearestRational(withPrecision: precision)
        }
    }
    
    var description: String {
        return "\(self.num)/\(self.den)"
    }
    
    static func == (left: Rational, right: Rational) -> Bool {
        let lreduced = left.reduced
        let rreduced = right.reduced
        return lreduced.num == rreduced.num && lreduced.den == rreduced.den
    }
    
    static func + (left: Rational, right: Rational) -> Rational {
        return Rational(left.num * right.den + right.num * left.den, left.den * right.den).reduced
    }
    
    static func - (left: Rational, right: Rational) -> Rational {
        return Rational(left.num * right.den - right.num * left.den, left.den * right.den).reduced
    }
    
    static func * (left: Rational, right: Rational) -> Rational {
        return Rational(left.num * right.num, left.den * right.den).reduced
    }
    
    static func / (left: Rational, right: Rational) -> Rational {
        return Rational(left.num * right.den, left.den * right.num).reduced
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

extension Double {
    init(_ rational: Rational) {
        self = Double(rational.num) / Double(rational.den)
    }
    
    func toNearestRational(withPrecision: Int, epsilon: Double = 0.001) -> (Rational, Double?) {
        let higherRational = Rational(Int((self * Double(withPrecision)).rounded(.up)), withPrecision).reduced
        let lowerRational = Rational(Int((self * Double(withPrecision)).rounded(.down)), withPrecision).reduced
        
        let upperError = Double(higherRational) - self
        let lowerError = self - Double(lowerRational)
        
        if upperError <= epsilon {
            return (higherRational, nil)
        } else if lowerError <= epsilon {
            return (lowerRational, nil)
        } else if upperError < lowerError {
            return (higherRational, upperError)
        } else {
            return (lowerRational, -lowerError)
        }
    }
}
