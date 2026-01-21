import Foundation

enum EvaluationError: LocalizedError, Equatable {
    case divisionByZero, incompatibleUnits

    var errorDescription: String? {
        switch self {
        case .divisionByZero: "This expression divides by zero."
        case .incompatibleUnits: "This expression has incompatible units (e.g. mixing length and area)."
        }
    }
}

