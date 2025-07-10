import Testing
@testable import WoodworkingCalculator

struct WoodworkingCalculatorParserTests {
    @Test("parseFraction", arguments: [
        ("1/2", Fraction(1, 2)),
        ("3-3/4", Fraction(15, 4)),
        ("3 3/4", Fraction(15, 4)),
        ("3   -  3/4", Fraction(15, 4)),
        ("3--3/4", nil),
        ("1 /2", nil),
        ("1/ 2", nil),
        ("1 / 2", nil),
    ]) func testParseFraction(input: String, expected: Fraction?) throws {
        let actual = parseFraction(input)
        if expected == nil {
            #expect(actual == nil)
        } else if actual == nil {
            Issue.record("Unexpected nil result")
        } else {
            #expect(actual!.1 == .Fraction)
            if case .fraction(let actual) = actual!.0 {
                #expect(actual == expected)
            } else {
                Issue.record("Expected parsed value to be a .fraction but it was not")
            }
        }
    }
}
