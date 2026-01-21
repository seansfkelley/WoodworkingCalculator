enum Dimension: Equatable, CustomStringConvertible {
    // will adopt whatever it is combined with
    case unassigned
    // 0 = unitless
    // 1 = length
    // 2 = area
    // etc.
    case assigned(Int)

    var description: String {
        switch self {
            case .unassigned: ""
            case .assigned(let value): "^\(value)"
        }
    }

    static func + (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs, rhs) {
        case (.unassigned, let other), (let other, .unassigned):
            .success(other)
        case (.assigned(let left), .assigned(let right)):
            left == right ? .success(.assigned(left)) : .failure(.incompatibleUnits)
        }
    }
    
    static func - (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs, rhs) {
        case (.unassigned, let other), (let other, .unassigned):
            .success(other)
        case (.assigned(let left), .assigned(let right)):
            left == right ? .success(.assigned(left)) : .failure(.incompatibleUnits)
        }
    }
    
    static func * (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs, rhs) {
        case (.unassigned, let other), (let other, .unassigned):
            .success(other)
        case (.assigned(let left), .assigned(let right)):
            .success(.assigned(left + right))
        }
    }
    
    static func / (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs, rhs) {
        case (.unassigned, let other), (let other, .unassigned):
            .success(other)
        case (.assigned(let left), .assigned(let right)):
            .success(.assigned(left - right))
        }
    }
}

