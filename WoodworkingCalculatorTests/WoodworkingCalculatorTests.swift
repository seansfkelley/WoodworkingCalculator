import Testing
@testable import WoodworkingCalculator

struct WoodworkingCalculatorTests {
    @Test(arguments: [("1/2", Fraction(1, 2))]) func test(_ input: (String, Fraction)) throws {
        #expect(try parse(input.0).evaluate() == .rational(input.1))
    }
}
