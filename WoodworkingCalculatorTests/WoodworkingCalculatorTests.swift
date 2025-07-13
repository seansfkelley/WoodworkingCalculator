import Testing
@testable import WoodworkingCalculator

struct WoodworkingCalculatorTests {
    @Test("simple parsing", arguments: [
        ("1/2", Rational(1, 2)),
        ("3.5", Rational(7, 2)),
    ]) func test(_ input: (String, Rational)) throws {
        #expect(try parse(input.0).evaluate() == .rational(input.1))
    }
}
