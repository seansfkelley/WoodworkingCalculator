internal enum WoodworkingCalculatorToken {
    case void
    case dimension(Dimension)
    case integer(Int)
    case rational(UncheckedRational)
    case real(Double)
}

typealias LexedTokenData = (WoodworkingCalculatorParser.CitronToken, WoodworkingCalculatorParser.CitronTokenCode)

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
        (.real(Double(input)!), .Real)
    } else {
        nil
    }
}

internal func parseInteger(_ input: String) -> LexedTokenData? {
    if let result = try? #/(?<int>[0-9]{1,10})\.?/#.wholeMatch(in: input) {
        (.integer(Int(result.int)!), .Integer)
    } else {
        nil
    }
}

internal func parseDimension(_ input: String) -> LexedTokenData? {
    if let result = try? #/\[(?<int>[0-9]{1,10})\]/#.wholeMatch(in: input) {
        (.dimension(Dimension(UInt(result.int)!)), .Dimension)
    } else {
        nil
    }
}

let lexer = CitronLexer<LexedTokenData>(rules: [
    .regexPattern("\\[[0-9]+\\]", parseDimension),
    .string("in", (.void, .Inches)),
    .string("ft", (.void, .Feet)),
    .string("mm", (.void, .Millimeters)),
    .string("cm", (.void, .Centimeters)),
    .string("m", (.void, .Meters)),
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
