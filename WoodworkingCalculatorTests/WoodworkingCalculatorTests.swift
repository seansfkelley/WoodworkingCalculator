import Testing
@testable import WoodworkingCalculator

struct WoodworkingCalculatorTests {
    // Serialized: Citron is not thread-safe.
    @Test("simple parsing", .serialized, arguments: [
        ("1/2", EvaluatedResult.rational(Rational(1, 2))),
        ("3.5", EvaluatedResult.real(3.5)),
    ]) func test(_ input: (String, EvaluatedResult)) throws {
        #expect(try parse(input.0).evaluate() == input.1)
    }
}
