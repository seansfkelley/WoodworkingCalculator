internal enum WoodworkingCalculatorToken {
    case void
    case dimension(Dimension)
    case integer(Int)
    case rational(UncheckedRational)
    case real(Double)
}

// n.b. this is a pair because the lexer has to be able to forward the token code (type),
// along with the payload, to the parser. The token code is controlled by citron, so we can't
// modify it.
typealias LexedTokenData = (WoodworkingCalculatorGrammar.CitronToken, WoodworkingCalculatorGrammar.CitronTokenCode)

internal func parseMixedNumber(_ input: String) -> LexedTokenData? {
    if let result = try? #/((?<whole>[0-9]{1,10}) +)?(?<num>[0-9]{1,10})/(?<den>[0-9]{1,10})/#.wholeMatch(in: input) {
        let whole = if let i = result.whole { Int(i)! } else { 0 }
        let num = Int(result.num)!
        let den = Int(result.den)!
        return (.rational(UncheckedRational(whole * den + num, den)), .MixedNumber)
    } else {
        return nil
    }
}

internal func parseReal(_ input: String) -> LexedTokenData? {
    if let _ = try? #/([0-9]{1,10})?\.[0-9]{1,10}/#.wholeMatch(in: input) {
        let real = Double(input)!
        return (.real(real), .Real)
    } else {
        return nil
    }
}

internal func parseInteger(_ input: String) -> LexedTokenData? {
    if let result = try? #/(?<int>[0-9]{1,10})\.?/#.wholeMatch(in: input) {
        let int = Int(result.int)!
        return (.integer(int), .Integer)
    } else {
        return nil
    }
}

internal func parseDimension(_ input: String, _ code: WoodworkingCalculatorGrammar.CitronTokenCode) -> LexedTokenData? {
    let exponent = if input.starts(with: "!") {
        Int(input.suffix(from: input.index(after: input.startIndex))).map { -$0 }
    } else if !input.isEmpty {
        Int(input)
    } else {
        1
    }

    return if let exponent {
        (.dimension(Dimension(exponent)), code)
    } else {
        nil
    }
}

let lexer = CitronLexer<LexedTokenData>(rules: [
    .regexPattern("in((!?)[0-9]+)?", {
        parseDimension(String($0.suffix(from: $0.index($0.startIndex, offsetBy: 2))), .DimensionedInches)
    }),
    .regexPattern("ft((!?)[0-9]+)?", {
        parseDimension(String($0.suffix(from: $0.index($0.startIndex, offsetBy: 2))), .DimensionedFeet)
    }),
    .regexPattern("mm((!?)[0-9]+)?", {
        parseDimension(String($0.suffix(from: $0.index($0.startIndex, offsetBy: 2))), .Millimeters)
    }),
    .regexPattern("cm((!?)[0-9]+)?", {
        parseDimension(String($0.suffix(from: $0.index($0.startIndex, offsetBy: 2))), .Centimeters)
    }),
    .regexPattern("m((!?)[0-9]+)?", {
        parseDimension(String($0.suffix(from: $0.index($0.startIndex, offsetBy: 1))), .Meters)
    }),
    .string("in", (.void, .Inches)),
    .string("ft", (.void, .Feet)),
    .regexPattern("([0-9]+ +)?[0-9]+/[0-9]+", parseMixedNumber),
    .regexPattern("([0-9]+)?\\.[0-9]+", parseReal),
    // Note that this permits a trailing dot, whereas the above does not. This makes it easier to
    // both define the reals regex, and means we can preserve the use of the rational datatype
    // when the real datatype is not actually necessary to represent the quantity, should someone
    // leave a trailing dot.
    .regexPattern("[0-9]+\\.?", parseInteger),
    .string("+", (.void, .Add)),
    .string("-", (.void, .Subtract)),
    .string("×", (.void, .Multiply)),
    .string("÷", (.void, .Divide)),
    .string("(", (.void, .LeftParen)),
    .string(")", (.void, .RightParen)),
    .regexPattern("\\s", { _ in nil })
])
