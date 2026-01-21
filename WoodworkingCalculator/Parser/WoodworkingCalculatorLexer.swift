internal enum WoodworkingCalculatorToken {
    case void
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
        let whole = if let i = result.whole { Int(i).unsafelyUnwrapped } else { 0 }
        let num = Int(result.num).unsafelyUnwrapped
        let den = Int(result.den).unsafelyUnwrapped
        return (.rational(UncheckedRational(whole * den + num, den)), .MixedNumber)
    } else {
        return nil
    }
}

internal func parseReal(_ input: String) -> LexedTokenData? {
    if let _ = try? #/([0-9]{1,10})?\.[0-9]{1,10}/#.wholeMatch(in: input) {
        let real = Double(input).unsafelyUnwrapped
        return (.real(real), .Real)
    } else {
        return nil
    }
}

internal func parseInteger(_ input: String) -> LexedTokenData? {
    if let result = try? #/(?<int>[0-9]{1,10})\.?/#.wholeMatch(in: input) {
        let int = Int(result.int).unsafelyUnwrapped
        return (.integer(int), .Integer)
    } else {
        return nil
    }
}

let lexer = CitronLexer<LexedTokenData>(rules: [
    .regexPattern("([0-9]+ +)?[0-9]+/[0-9]+", parseMixedNumber),
    .regexPattern("([0-9]+)?\\.[0-9]+", parseReal),
    // Note that this permits a trailing dot, whereas the above does not. This makes it easier to
    // both define the reals regex, and means we can preserve the use of the rational datatype
    // when the real datatype is not actually necessary to represent the quantity, should someone
    // leave a trailing dot.
    .regexPattern("[0-9]+\\.?", parseInteger),
    // For ease of managing "atomic" append, backspace and validation, give single-character
    // aliases to the metric units that will be formatted for prettier display later.
    .string("m", (.void, .Meters)),
    .string("c", (.void, .Centimeters)),
    .string("i", (.void, .Millimeters)),
    .string("'", (.void, .Feet)),
    .string("\"", (.void, .Inches)),
    .string("+", (.void, .Add)),
    .string("-", (.void, .Subtract)),
    .string("×", (.void, .Multiply)),
    .string("÷", (.void, .Divide)),
    .string("(", (.void, .LeftParen)),
    .string(")", (.void, .RightParen)),
    .regexPattern("\\s", { _ in nil })
])
