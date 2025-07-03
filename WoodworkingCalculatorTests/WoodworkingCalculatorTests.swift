import Testing
@testable import WoodworkingCalculator

struct WoodworkingCalculatorTests {

    @Test(arguments: [("1/2", (1, 2))]) func example(_ input: (String, Fraction)) async throws {
        #expect(try parse(input.0).evaluate() == input.1)
    }

}
