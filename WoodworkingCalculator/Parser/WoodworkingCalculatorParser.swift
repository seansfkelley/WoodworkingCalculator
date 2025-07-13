import RegexBuilder

enum Token {
    case void
    case integer(Int)
    case rational(Rational)
    case real(Double)
}

enum Evaluatable {
    // n.b. all quantities are in inches (or fractions thereof)
    case rational(Rational)
    case real(Double)
    indirect case add(Evaluatable, Evaluatable)
    indirect case subtract(Evaluatable, Evaluatable)
    indirect case multiply(Evaluatable, Evaluatable)
    indirect case divide(Evaluatable, Evaluatable)
}

enum EvaluatedResult: Equatable {
    case rational(Rational)
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

private let mixedNumberRegexString = "([0-9]+ +)?[0-9]+/[0-9]+"
// https://github.com/swiftlang/swift/issues/83022
private let mixedNumberRegex = Regex {
    Optionally {
        Capture {
            OneOrMore(.digit)
        } transform: { Int($0)! }
        OneOrMore { " " }
    }
    Capture {
        OneOrMore(.digit)
    } transform: { Int($0)! }
    "/"
    Capture {
        OneOrMore(.digit)
    } transform: { Int($0)! }
}

func parseMixedNumber(_ input: String) -> LexedTokenData? {
    if let match = try? mixedNumberRegex.wholeMatch(in: input) {
//        let whole = match.1 ?? 0
//        let num = match.2
//        let den = match.3
        print(match.1, match.2, match.3)
        return nil
//        return (.rational(Rational(whole * den + num, den)), .MixedNumber)
    } else {
        return nil
    }
}

// Note that `[0-9]+.` is considered an integer, and is covered below.
private let realRegexString = "([0-9]+)?\\.[0-9]+"
private let realRegex = Regex {
    Capture {
        Optionally {
            OneOrMore(.digit)
        }
        "."
        OneOrMore(.digit)
    } transform: { Double($0)! }
}

func parseReal(_ input: String) -> LexedTokenData? {
    if let match = try? realRegex.wholeMatch(in: input) {
        return (.real(match.1), .Real)
    } else {
        return nil
    }
}

private let integerRegexString = "[0-9]+\\.?"
private let integerRegex = Regex {
    Capture {
        OneOrMore(.digit)
    } transform: { Int($0)! }
    Optionally { "." }
}

func parseInteger(_ input: String) -> LexedTokenData? {
    if let match = try? integerRegex.wholeMatch(in: input) {
        return (.integer(match.1), .Integer)
    } else {
        return nil
    }
}

let lexer = CitronLexer<LexedTokenData>(rules: [
        .regexPattern(mixedNumberRegexString, parseMixedNumber),
        .regexPattern(realRegexString, parseReal),
        .regexPattern(integerRegexString, parseInteger),
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

// This function abuses the simplicity of the grammar whereby almost all tokens are single
// characters or repetitions of the same kind of character, so that it generally does not require
// multiple keystrokes "uninterrupted" to produce a valid token. This means that almost all
// cases where parsing terminates due to unexpected tokens, it's because the token is indeed
// illegal in that location, rather than it being an incomplete token that is being mis-parsed. The
// glaring exception is that rationals require two distinct numbers separated by a slash, which is
// a minimum of three keystrokes in a row.
func isValidPrefix(_ input: String) -> Bool {
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
    // This is where the abuse really happens. Since rationals are the only token that has no legal
    // prefixes that are shorter than 3 characters, we attempt to manufacture one to see if that
    // would make this a legal prefix. I don't think this risks any false positives w/r/t the slash
    // also functioning as an operator, but even if it doesn't, better too permissive than not
    // permissive enough.
    return check(input) || (input.contains(#/[0-9]$/#) && check(input + "/1")) || (input.contains(#/\/$/#) && check(input + "1"))
}

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
