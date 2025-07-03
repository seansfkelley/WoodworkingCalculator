enum Token {
    case void
    case integer(Int)
    case fraction(Fraction)
    case real(Double)
}

struct Fraction {
    var num: Int
    var den: Int
    
    init(_ num: Int, _ den: Int) {
        self.num = num
        self.den = den
    }
    
    func reduced() -> Fraction {
        var n = self.num
        var d = self.den
        while n % 2 == 0 && d % 2 == 0 {
            n /= 2
            d /= 2
        }
        return Fraction(n, d)
    }
    
    func roundedToPrecision(_ precision: Int) -> (Fraction, Double?) {
        // TODO: make sure precision is a power of 2
        if self.den <= precision {
            return (self, nil)
        } else {
            return Double(self).toNearestFraction(withPrecision: precision)
        }
    }
    
    static func + (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.den + right.num * left.den, left.den * right.den).reduced()
    }
    
    static func - (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.den - right.num * left.den, left.den * right.den).reduced()
    }
    
    static func * (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.num, left.den * right.den).reduced()
    }
    
    static func / (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.den, left.den * right.num).reduced()
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

enum Evaluatable {
    case rational(Fraction)
    case real(Double)
    indirect case add(Evaluatable, Evaluatable)
    indirect case subtract(Evaluatable, Evaluatable)
    indirect case multiply(Evaluatable, Evaluatable)
    indirect case divide(Evaluatable, Evaluatable)
}

enum EvaluatedResult {
    case rational(Fraction)
    case real(Double)
}

// 1/64th ~ 0.015, so this is VERY conservative about rounding to a fraction
let EPSILON = 0.001;
let HIGHEST_PRECISION: Int = 64;

extension Double {
    init(_ fraction: Fraction) {
        self = Double(fraction.num) / Double(fraction.den)
    }
    
    init(_ result: EvaluatedResult) {
        switch (result) {
        case .rational(let f):
            self = Double(f)
        case .real(let r):
            self = r
        }
    }
    
    func toNearestFraction(withPrecision: Int) -> (Fraction, Double?) {
        // TODO: make sure precision is a power of 2
        let upperFraction = Fraction(Int((self * Double(withPrecision)).rounded(.up)), withPrecision).reduced()
        let lowerFraction = Fraction(Int((self * Double(withPrecision)).rounded(.down)), withPrecision).reduced()
        
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

extension Evaluatable: CustomStringConvertible {
    var description: String {
        switch (self) {
        case .rational(let f):
            if f.den == 1 {
                return "\(f.num)"
            } else {
                return "\(f.num)/\(f.den)"
            }
        case .real(let r):
            return "\(r)"
        case .add(let left, let right):
            return "(\(left) + \(right))"
        case .subtract(let left, let right):
            return "(\(left) - \(right))"
        case .multiply(let left, let right):
            return "(\(left) * \(right))"
        case .divide(let left, let right):
            return "(\(left) / \(right))"
        }
    }
    
    func evaluate() -> EvaluatedResult {
        switch (self) {
        case .rational(let r):
            return .rational(r.reduced())
        case .real(let r):
            return .real(r)
        case .add(let left, let right):
            let l = left.evaluate()
            let r = right.evaluate()
            if case .rational(let lrational) = l, case .rational(let rrational) = r {
                return .rational(lrational + rrational)
            } else {
                return .real(Double(l) + Double(r))
            }
        case .subtract(let left, let right):
            let l = left.evaluate()
            let r = right.evaluate()
            if case .rational(let lrational) = l, case .rational(let rrational) = r {
                return .rational(lrational - rrational)
            } else {
                return .real(Double(l) - Double(r))
            }
        case .multiply(let left, let right):
            let l = left.evaluate()
            let r = right.evaluate()
            if case .rational(let lrational) = l, case .rational(let rrational) = r {
                return .rational(lrational * rrational)
            } else {
                return .real(Double(l) * Double(r))
            }
        case .divide(let left, let right):
            let l = left.evaluate()
            let r = right.evaluate()
            if case .rational(let lrational) = l, case .rational(let rrational) = r {
                return .rational(lrational / rrational)
            } else {
                return .real(Double(l) / Double(r))
            }
        }
    }
}

// n.b. this is a pair because the lexer has to be able to forward the token code (type),
// along with the payload, to the parser. The token code is controlled by citron, so we can't
// modify it.
typealias LexedTokenData = (WoodworkingCalculatorGrammar.CitronToken, WoodworkingCalculatorGrammar.CitronTokenCode)

func parseFraction(_ input: String) -> LexedTokenData? {
    if let result = try? #/((?<int>[0-9]+) +)?(?<num>[0-9]+)/(?<den>[0-9]+)/#.wholeMatch(in: input) {
        let int = if let i = result.int { Int(i).unsafelyUnwrapped } else { 0 }
        let num = Int(result.num).unsafelyUnwrapped
        let den = Int(result.den).unsafelyUnwrapped
        return (.fraction(Fraction(int * den + num, den)), .Fraction)
    } else {
        return nil
    }
}

func parseReal(_ input: String) -> LexedTokenData? {
    if let _ = try? #/([0-9]+)?\.[0-9]+/#.wholeMatch(in: input) {
        let real = Double(input).unsafelyUnwrapped
        let (fraction, error) = real.toNearestFraction(withPrecision: HIGHEST_PRECISION)
        if error == nil {
            return (.fraction(fraction), .Fraction)
        } else {
            return (.real(real), .Real)
        }
    } else {
        return nil
    }
}

func parseInteger(_ input: String) -> LexedTokenData? {
    if let result = try? #/(?<int>[0-9]+)\.?/#.wholeMatch(in: input) {
        let int = Int(result.int).unsafelyUnwrapped
        return (.integer(int), .Integer)
    } else {
        return nil
    }
}

let lexer = CitronLexer<LexedTokenData>(rules: [
        .regexPattern("([0-9]+ +)?[0-9]+/[0-9]+", parseFraction),
        .regexPattern("([0-9]+)?\\.[0-9]+", parseReal),
        .regexPattern("[0-9]+\\.?", parseInteger),
        .string("'", (.void, .Feet)),
        .string("\"", (.void, .Inches)),
        .string("+", (.void, .Add)),
        .string("-", (.void, .Subtract)),
        .string("*", (.void, .Multiply)),
        .string("x", (.void, .Multiply)),
        .string("/", (.void, .Divide)),
        .string("(", (.void, .LeftParen)),
        .string(")", (.void, .RightParen)),
        .regexPattern("\\s", { _ in nil })
    ])

func parse(_ input: String) throws -> Evaluatable {
    let parser = WoodworkingCalculatorGrammar()
    try lexer.tokenize(input) { (t, c) in
        try parser.consume(token: t, code: c)
    }
    return try parser.endParsing()
}
