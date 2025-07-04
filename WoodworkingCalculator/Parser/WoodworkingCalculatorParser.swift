enum Token {
    case void
    case integer(Int)
    case fraction(Fraction)
    case real(Double)
}

enum Evaluatable {
    case rational(Fraction)
    case real(Double)
    indirect case add(Evaluatable, Evaluatable)
    indirect case subtract(Evaluatable, Evaluatable)
    indirect case multiply(Evaluatable, Evaluatable)
    indirect case divide(Evaluatable, Evaluatable)
}

enum EvaluatedResult: Equatable {
    case rational(Fraction)
    case real(Double)
}

extension Double {
    init(_ result: EvaluatedResult) {
        switch (result) {
        case .rational(let f):
            self = Double(f)
        case .real(let r):
            self = r
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
            return .rational(r.reduced)
        case .real(let r):
            let (fraction, error) = r.toNearestFraction(withPrecision: HIGHEST_PRECISION)
            if error == nil {
                return .rational(fraction)
            } else {
                return .real(r)
            }
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
        return (.real(real), .Real)
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
