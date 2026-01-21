enum Quantity: Equatable {
    case rational(Rational)
    case real(Double)
}

enum EvaluatableCalculation: CustomStringConvertible {
    // n.b. all quantities are in inches (or fractions thereof)
    case rational(UncheckedRational)
    case real(Double)
    indirect case add(EvaluatableCalculation, EvaluatableCalculation)
    indirect case subtract(EvaluatableCalculation, EvaluatableCalculation)
    indirect case multiply(EvaluatableCalculation, EvaluatableCalculation)
    indirect case divide(EvaluatableCalculation, EvaluatableCalculation)
    
    var description: String {
        switch (self) {
        case .rational(let r): r.den == 1 ? r.num.description : r.description
        case .real(let r): r.description
        case .add(let left, let right): "(\(left) + \(right))"
        case .subtract(let left, let right): "(\(left) - \(right))"
        case .multiply(let left, let right): "(\(left) × \(right))"
        case .divide(let left, let right): "(\(left) ÷ \(right))"
        }
    }
    
    func evaluate() -> Result<Quantity, DivisionByZeroError> {
        switch self {
        case .rational(let r): r.checked.map { .rational($0) }
        case .real(let r): .success(.real(r))
        case .add(let left, let right): Self.evaluateBinaryOperator(left, (+), (+), right)
        case .subtract(let left, let right): Self.evaluateBinaryOperator(left, (-), (-), right)
        case .multiply(let left, let right): Self.evaluateBinaryOperator(left, (*), (*), right)
        case .divide(let left, let right):  Self.evaluateBinaryOperator(left, (/), (/), right)
        }
    }
    
    // This signature is pretty dumb and the implementation isn't much better, but it's the best
    // way I could determine to DRY up the binary operator stuff. Generics don't seem to work,
    // even with a dedicated "arithmetical" protocol that includes the four basic operators that
    // I make Double and Rational conform to. The compiler still gets mad about ambiguous calls.
    private static func evaluateBinaryOperator(
        _ left: EvaluatableCalculation,
        _ rationalOp: (Rational, Rational) -> Result<Rational, DivisionByZeroError>,
        _ doubleOp: (Double, Double) -> Double,
        _ right: EvaluatableCalculation
    ) -> Result<Quantity, DivisionByZeroError> {
        guard case .success(let l) = left.evaluate(), case .success(let r) = right.evaluate() else {
            return .failure(DivisionByZeroError())
        }
        
        
        return switch (l, r) {
        case (.rational(let leftRational), .rational(let rightRational)):
            rationalOp(leftRational, rightRational).map { .rational($0) }

        // Fallthroughs don't work here, unfortunately, due to changes in the type of the binding
        // pattern, so eat the cost of repetition.
            
        case (.real(let leftReal), .real(let rightReal)):
            .success(.real(doubleOp(leftReal, rightReal)))

        case (.rational(let leftRational), .real(let rightReal)):
            .success(.real(doubleOp(Double(leftRational), rightReal)))

        case (.real(let leftReal), .rational(let rightRational)):
            .success(.real(doubleOp(leftReal, Double(rightRational))))
        }
    }
    
    static func from(_ input: String) -> EvaluatableCalculation? {
        return try? parse(input, autoterminatingParentheticals: true)
    }
    
    // This function abuses the simplicity of the grammar whereby almost all tokens either:
    //   - single characters (e.g. operators)
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
    //
    // In the case of metric quantities, the grammar is specifically designed to be based on
    // single-character pseudo-units, because we treat the supported units as totally independent
    // and there is no concept of an SI prefix. This means we don't need to special-case validity
    // checks for them here, because you can't input only part of a unit (e.g. only "c" from "cm").
    static func isValidPrefix(_ input: String) -> Bool {
        func check(_ s: String) -> Bool {
            do {
                _ = try parse(s, autoterminatingParentheticals: false)
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
        // This is where the abuse really happens. Rationals and reals both have prefixes that
        // aren't any kind of legal token:
        //   - rational: "1/"
        //     - as a special case, "1 2" is only legal if the 2 is the beginning of a rational
        //   - real: "."
        //     - note that "0." is considered an integer, so "fully-qualified" reals are already
        //       handled as a matter of course (since reals are only in positions where another
        //       rule has an integer)
        //
        // If the expression is not already legal, this boolean expression attempts to manufacture
        // derivatives of it that would make the above cases legal and checks those too.
        return check(input)
            // rationals
            || (input.contains(/[0-9]$/) && check(input + "/1")) || (input.contains(#/\/$/#) && check(input + "1"))
            // reals
            || (input.contains(/\.$/) && check(input + "0"))
    }

    static func countMissingTrailingParens(_ input: String) -> Int {
        input.count(where: { $0 == "(" }) - input.count(where: { $0 == ")" })
    }
}

extension Double {
    init(_ result: Quantity) {
        switch (result) {
        case .rational(let f):
            self = Double(f)
        case .real(let r):
            self = r
        }
    }
}

internal enum Token {
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

private let lexer = CitronLexer<LexedTokenData>(rules: [
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

private func parse(_ input: String, autoterminatingParentheticals: Bool) throws -> EvaluatableCalculation {
    let parser = WoodworkingCalculatorGrammar()
    var missingRightParens = 0
    
    try lexer.tokenize(input) { (t, c) in
        if c == .LeftParen {
            missingRightParens += 1
        } else if c == .RightParen {
            missingRightParens -= 1
        }
        try parser.consume(token: t, code: c)
    }

    if autoterminatingParentheticals {
        for _ in 0..<missingRightParens {
            try parser.consume(token: .void, code: .RightParen)
        }
    }
    
    return try parser.endParsing()
}
