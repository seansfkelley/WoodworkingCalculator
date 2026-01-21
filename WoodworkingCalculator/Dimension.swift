struct Dimension: Equatable {
    // 0 = unassigned (will adopt whatever it is combined with)
    // 1 = unitless
    // 2 = length
    // 3 = area
    // etc.
    var value: Int
    
    init(_ value: Int) {
        self.value = value
    }
    
    static let unitless = Dimension(0)
    static let length = Dimension(1)

    static func + (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs.value, rhs.value) {
        case (0, let other), (let other, 0):
            .success(Dimension(other))
        case (let left, let right):
            left == right ? .success(Dimension(left)) : .failure(.incompatibleUnits)
        }
    }
    
    static func - (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs.value, rhs.value) {
        case (0, let other), (let other, 0):
            .success(Dimension(other))
        case (let left, let right):
            left == right ? .success(Dimension(left)) : .failure(.incompatibleUnits)
        }
    }
    
    static func * (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        .success(Dimension(lhs.value + rhs.value))
    }
    
    static func / (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        .success(Dimension(lhs.value - rhs.value))
    }
}
