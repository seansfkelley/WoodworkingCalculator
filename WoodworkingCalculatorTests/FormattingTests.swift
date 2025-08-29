import Testing
@testable import Wood_Calc

struct FormattingTests {
    @Test("formatAsUsCustomary (inches)", arguments: [
        (Rational(0, 1), "0\""),
        (Rational(1, 2), "1/2\""),
        (Rational(1, -2), "-1/2\""),
        (Rational(6, 1), "6\""),
        (Rational(12, 1), "12\""),
        (Rational(48, 1), "48\""),
        (Rational(13, 1), "13\""),
        (Rational(49, 1), "49\""),
        (Rational(99, 2), "49 1/2\""),
    ]) func testFormatAsUsCustomaryInches(input: Rational, expected: String) throws {
        #expect(formatAsUsCustomary(input, .inches) == expected)
    }
    
    @Test("formatAsUsCustomary (feet and inches)", arguments: [
        (Rational(0, 1), "0\""),
        (Rational(6, 1), "6\""),
        (Rational(12, 1), "1'"),
        (Rational(48, 1), "4'"),
        (Rational(25, 2), "1' 1/2\""),
        (Rational(-25, 2), "-1' 1/2\""),
        (Rational(13, 1), "1' 1\""),
        (Rational(49, 1), "4' 1\""),
        (Rational(99, 2), "4' 1 1/2\""),
    ]) func testFormatAsUsCustomaryFeet(input: Rational, expected: String) throws {
        #expect(formatAsUsCustomary(input, .feet) == expected)
    }
    
    @Test("formatMetric", arguments: [
        (0.123, 0, "0"),
        (0.12345, 2, "0.12"),
        (0.1001, 3, "0.1"),
        (0.04, 1, "0"),
        (0.05, 1, "0.1"),
        (0.06, 1, "0.1"),
        (1000, 0, "1000"),
    ]) func testFormatMetric(number: Double, precision: Int, expected: String) throws {
        #expect(formatMetric(number, precision: precision) == expected)
    }
    
    @Test("fancyDescription", arguments: [
        (Rational(1, 2), "¹⁄₂"),
        (Rational(4, 2), "2"),
    ]) func fancyDescription(input: Rational, expected: String) throws {
        #expect(input.fancyDescription == expected)
    }
}
