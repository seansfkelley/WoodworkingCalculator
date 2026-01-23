import Foundation

enum EvaluationError: LocalizedError, Equatable {
    case divisionByZero, incompatibleDimensions, negativeDimension

    var errorDescription: String? {
        switch self {
        case .divisionByZero: "This input divides by zero."
        case .incompatibleDimensions: "This input is adding or subtracting values with different unit types, such as length and area."
        case .negativeDimension: "This input would result in an unsupported unit type, such as inverse area."
        }
    }
}

