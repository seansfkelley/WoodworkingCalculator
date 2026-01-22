import Foundation

enum EvaluationError: LocalizedError, Equatable {
    case syntaxError, divisionByZero, incompatibleDimensions, negativeDimension

    var errorDescription: String? {
        switch self {
        case .syntaxError: "This expression cannot be evaluated as written."
        case .divisionByZero: "This expression divides by zero."
        case .incompatibleDimensions: "This expression has incompatible units (e.g. mixing length and area)."
        case .negativeDimension: "This expression would result in unsupported units."
        }
    }
}

