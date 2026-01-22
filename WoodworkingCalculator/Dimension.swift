import Foundation

precedencegroup DimensionExponentiationPrecedence {
    associativity: left
    higherThan: MultiplicationPrecedence
}

// This isn't quite exponentiation. It...
//
// ...is only defined for integer exponents 1 or higher, because dimensions are integer quantities
// and we have no interest in supporting negative dimensions ("1 over", etc.).
//
// ...preserves the sign of the base regardless of the exponent, which isn't necessary in the
// current parser architecture (since unary negation occurs separately and binds less tightly than
// dimension) but will be if unary negation is ever pushed down to bind more tightly than dimension.
infix operator ^^: DimensionExponentiationPrecedence

struct Dimension: Equatable, CustomStringConvertible {
    // 0 = unassigned (will adopt whatever it is combined with)
    // 1 = unitless
    // 2 = length
    // 3 = area
    // etc.
    var value: UInt

    var description: String { "[\(value)]" }

    init(_ value: UInt) {
        self.value = value
    }
    
    static let unitless = Dimension(0)
    static let length = Dimension(1)
    static let area = Dimension(2)
    static let volume = Dimension(3)

    static func + (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs.value, rhs.value) {
        case (0, let other), (let other, 0):
            .success(Dimension(other))
        case (let left, let right):
            left == right ? .success(Dimension(left)) : .failure(.incompatibleDimensions)
        }
    }
    
    static func - (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs.value, rhs.value) {
        case (0, let other), (let other, 0):
            .success(Dimension(other))
        case (let left, let right):
            left == right ? .success(Dimension(left)) : .failure(.incompatibleDimensions)
        }
    }
    
    static func * (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        .success(Dimension(lhs.value + rhs.value))
    }
    
    static func / (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        if rhs.value > lhs.value {
            .failure(.negativeDimension)
        } else {
            .success(Dimension(lhs.value - rhs.value))
        }
    }

    static func ^^ (lhs: Int, rhs: Dimension) -> Int {
        guard rhs.value > 1 else {
            return lhs
        }

        let sign = lhs.signum()
        let base = abs(lhs)

        var result = base
        for _ in 1..<rhs.value {
            result *= base
        }
        
        return result * sign
    }
    
    static func ^^ (lhs: Double, rhs: Dimension) -> Double {
        guard rhs.value > 1 else {
            return lhs
        }
        
        return pow(lhs, Double(rhs.value))
    }
    
    static func ^^ (lhs: UncheckedRational, rhs: Dimension) -> UncheckedRational {
        guard rhs.value > 1 else {
            return lhs
        }
        
        let numSign = lhs.num.signum()
        let denSign = lhs.den.signum()
        let absNum = abs(lhs.num)
        let absDen = abs(lhs.den)
        
        var resultNum = absNum
        var resultDen = absDen
        
        for _ in 1..<rhs.value {
            resultNum *= absNum
            resultDen *= absDen
        }
        
        return UncheckedRational(resultNum * numSign, resultDen * denSign)
    }
}
