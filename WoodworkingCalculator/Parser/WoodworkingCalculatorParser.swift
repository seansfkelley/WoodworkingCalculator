enum Token {
    case void
    case integer(Int)
    case fraction(Int, Int)
}

typealias Fraction = (Int, Int)

func reduce(_ f: Fraction) -> Fraction {
    var (n, d) = f
    while n % 2 == 0 && d % 2 == 0 {
        n /= 2
        d /= 2
    }
    return (n, d)
}

func formatFraction(_ f: Fraction) -> String {
    let (n, d) = reduce(f)
    if d == 1 {
        if n > 12 {
            return "\(n / 12)' \(n % 12)\""
        } else {
            return "\(n)\""
        }
    } else {
        if n > 12 * d {
            return "\(n / (12 * d))' \(formatFraction((n % (12 * d), d)))"
        } else if n > d {
            return "\(n / d)-\(n % d)/\(d)\""
        } else {
            return "\(n)/\(d)\""
        }
    }
}

enum Evaluatable {
    case quantity(Int, Int)
    indirect case add(Evaluatable, Evaluatable)
    indirect case subtract(Evaluatable, Evaluatable)
    indirect case multiply(Evaluatable, Evaluatable)
    indirect case divide(Evaluatable, Evaluatable)
}

extension Evaluatable: CustomStringConvertible {
    var description: String {
        switch (self) {
        case .quantity(let n, let d):
            return "\(n)/\(d)"
        case .add(let left, let right):
            return "(+ \(left) \(right))"
        case .subtract(let left, let right):
            return "(- \(left) \(right))"
        case .multiply(let left, let right):
            return "(* \(left) \(right))"
        case .divide(let left, let right):
            return "(/ \(left) \(right))"
        }
    }
    
    func evaluate() -> Fraction {
        switch (self) {
        case .quantity(let n, let d):
            return reduce((n, d))
        case .add(let left, let right):
            let l = left.evaluate()
            let r = right.evaluate()
            return reduce((l.0 * r.1 + r.0 * l.1, l.1 * r.1))
        case .subtract(let left, let right):
            let l = left.evaluate()
            let r = right.evaluate()
            return reduce((l.0 * r.1 - r.0 * l.1, l.1 * r.1))
        case .multiply(let left, let right):
            let l = left.evaluate()
            let r = right.evaluate()
            return reduce((l.0 * r.0, l.1 * r.1))
        case .divide(let left, let right):
            let l = left.evaluate()
            let r = right.evaluate()
            return reduce((l.0 * r.1, l.1 * r.0))
        }
    }
}

let parser = WoodworkingCalculatorGrammar()

typealias Lexer = CitronLexer<(WoodworkingCalculatorGrammar.CitronToken, WoodworkingCalculatorGrammar.CitronTokenCode)>

func parseFraction(_ input: String) -> Token? {
    if let result = try? #/(?<int>[0-9]+) +(?<num>[0-9]+)/(?<den>[0-9]+)/#.wholeMatch(in: input) {
        let int = Int(result.int).unsafelyUnwrapped
        let num = Int(result.num).unsafelyUnwrapped
        let den = Int(result.den).unsafelyUnwrapped
        return .fraction(int * den + num, den)
    }
    return nil
}

let lexer = Lexer(rules: [
        .regexPattern("[0-9]+ +[0-9]+/[0-9]+", { str in
            if let parsed = parseFraction(str) {
                return (parsed, .Fraction)
            }
            return nil
        }),
        .regexPattern("[0-9]+", { str in
            if let number = Int(str) {
                return (.integer(number), .Integer)
            }
            return nil
        }),
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
