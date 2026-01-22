struct UncheckedRational: CustomStringConvertible {
    let num: Int
    let den: Int
    
    init(_ num: Int, _ den: Int) {
        self.num = num
        self.den = den
    }
    
    var description: String { "\(num)/\(den)" }
    
    var checked: Result<Rational, EvaluationError> {
        if den == 0 {
            .failure(.divisionByZero)
        } else {
            .success(Rational(num, den))
        }
    }
}

struct Rational: Equatable, Hashable, CustomStringConvertible {
    let num: Int
    let den: Int
    
    fileprivate init(_ num: Int, _ den: Int) {
        let (n, d) = reduce(num, den)
        self.num = n
        self.den = d
    }
    
    func roundedToDenominator(_ denonimator: Int, epsilon: Double) -> (Rational, Double?) {
        if den <= denonimator && den % denonimator == 0 {
            (self, nil)
        } else {
            Double(self).toNearestRational(withDenominator: denonimator, epsilon: epsilon)
        }
    }
    
    var description: String {
        "\(num)/\(den)"
    }
    
    func signum() -> Int {
        if num.signum() == 0 {
            0
        } else if num.signum() * den.signum() == 1 {
            1
        } else {
            -1
        }
    }
    
    static func == (left: Rational, right: Rational) -> Bool {
        return left.num == right.num && left.den == right.den
    }
    
    static func + (left: Rational, right: Rational) -> Result<Rational, EvaluationError> {
        UncheckedRational(left.num * right.den + right.num * left.den, left.den * right.den).checked
    }
    
    static func - (left: Rational, right: Rational) -> Result<Rational, EvaluationError> {
        UncheckedRational(left.num * right.den - right.num * left.den, left.den * right.den).checked
    }
    
    static func * (left: Rational, right: Rational) -> Result<Rational, EvaluationError> {
        UncheckedRational(left.num * right.num, left.den * right.den).checked
    }
    
    static func / (left: Rational, right: Rational) -> Result<Rational, EvaluationError> {
        UncheckedRational(left.num * right.den, left.den * right.num).checked
    }
}

private func reduce(_ num: Int, _ den: Int) -> (Int, Int) {
    var n = num
    var d = den
    if (n.signum() == -1 && d.signum() == -1) || (n.signum() == 1 && d.signum() == -1) {
        n = -n
        d = -d
    }
    let divisor = gcd(abs(n), abs(d))
    return (n / divisor, d / divisor)
}


private func gcd(_ a: Int, _ b: Int) -> Int {
    let r = a % b
    return r == 0 ? b : gcd(b, r)
}

extension Double {
    init(_ rational: Rational) {
        self = Double(rational.num) / Double(rational.den)
    }
    
    func toNearestRational(withDenominator precision: Int, epsilon: Double) -> (Rational, Double?) {
        let p = precision <= 0 ? 1 : precision
        let higherRational = Rational(Int((self * Double(p)).rounded(.up)), p)
        let lowerRational = Rational(Int((self * Double(p)).rounded(.down)), p)
        
        let upperError = Double(higherRational) - self
        let lowerError = self - Double(lowerRational)
        
        return if upperError <= epsilon {
            (higherRational, nil)
        } else if lowerError <= epsilon {
            (lowerRational, nil)
        } else if upperError < lowerError {
            (higherRational, upperError)
        } else {
            (lowerRational, -lowerError)
        }
    }
}
