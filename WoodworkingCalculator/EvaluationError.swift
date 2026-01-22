import Foundation

enum EvaluationError: LocalizedError, Equatable {
    case divisionByZero, incompatibleDimensions, negativeDimension

    var errorDescription: String? {
        switch self {
        case .divisionByZero: "This expression divides by zero."
        case .incompatibleDimensions: "This expression has incompatible units (e.g. mixing length and area)."
        case .negativeDimension: "This expression would result in unsupported units."
        }
    }
}

