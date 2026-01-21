struct Dimension: Equatable, CustomStringConvertible {
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

    var description: String {
        value == 0 ? "" : "^\(value)"
    }

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
        switch (lhs.value, rhs.value) {
        case (0, let other), (let other, 0):
            .success(Dimension(other))
        case (let left, let right):
            .success(Dimension(left + right))
        }
    }
    
    static func / (lhs: Dimension, rhs: Dimension) -> Result<Dimension, EvaluationError> {
        switch (lhs.value, rhs.value) {
        case (0, let other), (let other, 0):
            .success(Dimension(other))
        case (let left, let right):
            .success(Dimension(left - right))
        }
    }
}
