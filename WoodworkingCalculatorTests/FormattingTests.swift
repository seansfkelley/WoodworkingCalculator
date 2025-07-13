import Testing
@testable import WoodworkingCalculator

struct FormattingTests {
    @Test("formatAsUsCustomary", arguments: [
        (Rational(0, 1), "0\""),
        (Rational(12, 1), "1'"),
        (Rational(48, 1), "4'"),
        (Rational(13, 1), "1' 1\""),
        (Rational(49, 1), "4' 1\""),
        (Rational(99, 2), "4' 1 1/2\""),
    ]) func testFormatAsUsCustomary(input: Rational, expected: String) throws {
        #expect(formatAsUsCustomary(input) == expected)
    }
    
    @Test("fancyDescription", arguments: [
        (Rational(1, 2), "¹⁄₂"),
        (Rational(4, 2), "2"),
    ]) func fancyDescription(input: Rational, expected: String) throws {
        #expect(input.fancyDescription == expected)
    }
}
