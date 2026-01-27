import Foundation

infix operator ~==: ComparisonPrecedence

protocol FuzzyEquatable {
    static func ~== (lhs: Self, rhs: Self) -> Bool
}

extension FuzzyEquatable where Self: Equatable {
    static func ~== (lhs: Self, rhs: Self) -> Bool {
        return lhs == rhs
    }
}

extension FuzzyEquatable where Self: BinaryFloatingPoint {
    static func ~== (lhs: Self, rhs: Self) -> Bool {
        if lhs.isNaN && rhs.isNaN {
            return false
        }

        if lhs.isInfinite && rhs.isInfinite {
            return lhs.sign == rhs.sign
        }

        if lhs.isInfinite || rhs.isInfinite {
            return false
        }
        
        return abs(lhs - rhs) <= Self.ulpOfOne
    }
}

extension FuzzyEquatable where Self: BinaryInteger {
    static func ~== (lhs: Self, rhs: Self) -> Bool {
        return lhs == rhs
    }
}

extension Double: FuzzyEquatable {}
extension Float: FuzzyEquatable {}
extension Float16: FuzzyEquatable {}

extension Int: FuzzyEquatable {}
extension Int8: FuzzyEquatable {}
extension Int16: FuzzyEquatable {}
extension Int32: FuzzyEquatable {}
extension Int64: FuzzyEquatable {}
extension UInt: FuzzyEquatable {}
extension UInt8: FuzzyEquatable {}
extension UInt16: FuzzyEquatable {}
extension UInt32: FuzzyEquatable {}
extension UInt64: FuzzyEquatable {}

// MARK: - Result Conformance

extension Result: FuzzyEquatable where Success: FuzzyEquatable, Failure: FuzzyEquatable {
    static func ~== (lhs: Result<Success, Failure>, rhs: Result<Success, Failure>) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lValue), .success(let rValue)):
            return lValue ~== rValue
        case (.failure(let lError), .failure(let rError)):
            return lError ~== rError
        default:
            return false
        }
    }
}

// MARK: - Custom Type Conformances
extension Quantity: FuzzyEquatable {
    static func ~== (lhs: Quantity, rhs: Quantity) -> Bool {
        switch (lhs, rhs) {
        case (.rational(let lRat, let lDim), .rational(let rRat, let rDim)):
            return lRat == rRat && lDim == rDim
        case (.real(let lVal, let lDim), .real(let rVal, let rDim)):
            return lVal ~== rVal && lDim == rDim
        default:
            return false
        }
    }
}

extension EvaluationError: FuzzyEquatable {}

