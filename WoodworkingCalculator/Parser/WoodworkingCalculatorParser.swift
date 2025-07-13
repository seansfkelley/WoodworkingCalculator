internal enum Token {
    case void
    case integer(Int)
    case rational(Rational)
    case real(Double)
}

enum EvaluatableCalculation {
    // n.b. all quantities are in inches (or fractions thereof)
    case rational(Rational)
    case real(Double)
    indirect case add(EvaluatableCalculation, EvaluatableCalculation)
    indirect case subtract(EvaluatableCalculation, EvaluatableCalculation)
    indirect case multiply(EvaluatableCalculation, EvaluatableCalculation)
    indirect case divide(EvaluatableCalculation, EvaluatableCalculation)
}

enum CalculationResult: Equatable {
    case rational(Rational)
    case real(Double)
}

extension Double {
    init(_ result: CalculationResult) {
        switch (result) {
        case .rational(let f):
            self = Double(f)
        case .real(let r):
            self = r
        }
    }
}

extension EvaluatableCalculation: CustomStringConvertible {
    var description: String {
        switch (self) {
        case .rational(let r):
            if r.den == 1 {
                return "\(r.num)"
            } else {
                return r.description
            }
        case .real(let r):
            return "\(r)"
        case .add(let left, let right):
            return "(\(left) + \(right))"
        case .subtract(let left, let right):
            return "(\(left) - \(right))"
        case .multiply(let left, let right):
            return "(\(left) × \(right))"
        case .divide(let left, let right):
            return "(\(left) / \(right))"
        }
    }
    
    func evaluate() -> CalculationResult {
        switch (self) {
        case .rational(let r):
            return .rational(r.reduced)
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
    
    static func from(_ input: String) -> EvaluatableCalculation? {
        return try? parse(input)
    }
    
    // This function abuses the simplicity of the grammar whereby almost all tokens are:
    //   - single characters (e.g. oeprators)
    //   - repetitions of the same kind of character (e.g. integers)
    //   - in the same position as, and a superset of, another token meeting the above criteria (e.g.
    //     reals requiring a dot, but alternating with integers that _allow_ a dot)
    //
    // This means it generally does not require multiple keystrokes "uninterrupted" to produce a valid
    // token in any given position. In turn, this means that in almost all cases where parsing
    // terminates due to unexpected tokens, it's because some token is indeed illegal in that location,
    // rather than it being an incomplete token that is being mis-parsed. The glaring exception is that
    // rationals require two distinct numbers separated by a slash, which is a minimum of three
    // keystrokes in a row.
    static func isValidPrefix(_ input: String) -> Bool {
        func check(_ s: String) -> Bool {
            do {
                _ = try parse(s)
                return true
            } catch is CitronParserUnexpectedEndOfInputError {
                return true
            } catch is _CitronParserUnexpectedTokenError<WoodworkingCalculatorGrammar.CitronToken, WoodworkingCalculatorGrammar.CitronTokenCode> {
                return false
            } catch {
                return false
            }
        }
        
        // HACK HACK HACK
        //
        // This is where the abuse really happens. Since rationals are the only token that has no legal
        // prefixes that are shorter than 3 characters, we attempt to manufacture one to see if that
        // would make this a legal prefix. I don't think this risks any false positives w/r/t the slash
        // also functioning as an operator, but even if it doesn't, better too permissive than not
        // permissive enough.
        //
        // Note that reals require at least 2 characters, but an integer is a legal prefix to a real
        // that can become a legal real with just one keystroke (a dot).
        return check(input) || (input.contains(#/[0-9]$/#) && check(input + "/1")) || (input.contains(#/\/$/#) && check(input + "1"))
    }
}

// n.b. this is a pair because the lexer has to be able to forward the token code (type),
// along with the payload, to the parser. The token code is controlled by citron, so we can't
// modify it.
typealias LexedTokenData = (WoodworkingCalculatorGrammar.CitronToken, WoodworkingCalculatorGrammar.CitronTokenCode)

internal func parseMixedNumber(_ input: String) -> LexedTokenData? {
    if let result = try? #/((?<whole>[0-9]+) +)?(?<num>[0-9]+)/(?<den>[0-9]+)/#.wholeMatch(in: input) {
        let whole = if let i = result.whole { Int(i).unsafelyUnwrapped } else { 0 }
        let num = Int(result.num).unsafelyUnwrapped
        let den = Int(result.den).unsafelyUnwrapped
        return (.rational(Rational(whole * den + num, den)), .MixedNumber)
    } else {
        return nil
    }
}

internal func parseReal(_ input: String) -> LexedTokenData? {
    if let _ = try? #/([0-9]+)?\.[0-9]+/#.wholeMatch(in: input) {
        let real = Double(input).unsafelyUnwrapped
        return (.real(real), .Real)
    } else {
        return nil
    }
}

internal func parseInteger(_ input: String) -> LexedTokenData? {
    if let result = try? #/(?<int>[0-9]+)\.?/#.wholeMatch(in: input) {
        let int = Int(result.int).unsafelyUnwrapped
        return (.integer(int), .Integer)
    } else {
        return nil
    }
}

private let lexer = CitronLexer<LexedTokenData>(rules: [
    .regexPattern("([0-9]+ +)?[0-9]+/[0-9]+", parseMixedNumber),
    .regexPattern("([0-9]+)?\\.[0-9]+", parseReal),
    .regexPattern("[0-9]+\\.?", parseInteger),
    .string("'", (.void, .Feet)),
    .string("\"", (.void, .Inches)),
    .string("+", (.void, .Add)),
    .string("-", (.void, .Subtract)),
    .string("*", (.void, .Multiply)),
    .string("x", (.void, .Multiply)),
    .string("×", (.void, .Multiply)),
    .string("/", (.void, .Divide)),
    .string("÷", (.void, .Divide)),
    .string("(", (.void, .LeftParen)),
    .string(")", (.void, .RightParen)),
    .regexPattern("\\s", { _ in nil })
])

fileprivate func parse(_ input: String) throws -> EvaluatableCalculation {
    let parser = WoodworkingCalculatorGrammar()
    try lexer.tokenize(input) { (t, c) in
        try parser.consume(token: t, code: c)
    }
    return try parser.endParsing()
}
