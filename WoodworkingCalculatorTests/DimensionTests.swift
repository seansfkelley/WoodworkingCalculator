import Testing
@testable import Wood_Calc

@Suite
struct DimensionTests {
    @Test<[(Result<Dimension, EvaluationError>, Result<Dimension, EvaluationError>)]>("Dimension operators", arguments: [
        // Addition
        (Dimension(2) + Dimension(2), .success(Dimension(2))),
        (Dimension.unitless + Dimension.length, .success(Dimension.length)),
        (Dimension.length + Dimension.unitless, .success(Dimension.length)),
        (Dimension(1) + Dimension(2), .failure(.incompatibleDimensions)),

        // Subtraction
        (Dimension(3) - Dimension(3), .success(Dimension(3))),
        (Dimension(2) - Dimension(1), .failure(.incompatibleDimensions)),
        (Dimension.unitless - Dimension.length, .success(Dimension.length)),
        (Dimension.length - Dimension.unitless, .success(Dimension.length)),

        // Multiplication
        (Dimension(1) * Dimension(2), .success(Dimension(3))),

        // Division
        (Dimension(2) / Dimension(1), .success(Dimension(1))),
        (Dimension(1) / Dimension(2), .failure(.negativeDimension)),
    ])
    func dimensionOperations(actual: Result<Dimension, EvaluationError>, expected: Result<Dimension, EvaluationError>) {
        #expect(actual == expected)
    }
    
    @Test("Dimension-exponentiation operator (Int)", arguments: [
        (5 ^^ Dimension(0), 5),
        (-2 ^^ Dimension(2), -4),
        (2 ^^ Dimension(3), 8),
    ])
    func dimensionExponentiationInt(actual: Int, expected: Int) {
        #expect(actual == expected)
    }

    @Test("Dimension-exponentiation operator (Double)", arguments: [
        (5.0 ^^ Dimension(0), 5.0),
        (-3.5 ^^ Dimension(2), -12.25),
        (2.0 ^^ Dimension(3), 8.0),
    ])
    func dimensionExponentiationDouble(actual: Double, expected: Double) {
        #expect(actual == expected)
    }

    @Test("Dimension-exponentiation operator (UncheckedRational)", arguments: [
        (UncheckedRational(3, 4) ^^ Dimension(0), UncheckedRational(3, 4)),
        (UncheckedRational(-2, 3) ^^ Dimension(2), UncheckedRational(-4, 9)),
        (UncheckedRational(1, 2) ^^ Dimension(3), UncheckedRational(1, 8)),
    ])
    func dimensionExponentiationUncheckedRational(actual: UncheckedRational, expected: UncheckedRational) {
        #expect(actual.num == expected.num)
        #expect(actual.den == expected.den)
    }
}
