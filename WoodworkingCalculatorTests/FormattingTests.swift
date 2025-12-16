import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct FormattingTests {
    @Test("formatAsUsCustomary (inches)", arguments: [
        (rational(0, 1), "0\""),
        (rational(1, 2), "1/2\""),
        (rational(1, -2), "-1/2\""),
        (rational(6, 1), "6\""),
        (rational(12, 1), "12\""),
        (rational(48, 1), "48\""),
        (rational(13, 1), "13\""),
        (rational(49, 1), "49\""),
        (rational(99, 2), "49 1/2\""),
    ]) func testFormatAsUsCustomaryInches(input: Rational, expected: String) throws {
        #expect(formatAsUsCustomary(input, .inches) == expected)
    }
    
    @Test("formatAsUsCustomary (feet and inches)", arguments: [
        (rational(0, 1), "0\""),
        (rational(6, 1), "6\""),
        (rational(12, 1), "1'"),
        (rational(48, 1), "4'"),
        (rational(25, 2), "1' 1/2\""),
        (rational(-25, 2), "-1' 1/2\""),
        (rational(13, 1), "1' 1\""),
        (rational(49, 1), "4' 1\""),
        (rational(99, 2), "4' 1 1/2\""),
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
        (rational(1, 2), "¹⁄₂"),
        (rational(4, 2), "2"),
    ]) func fancyDescription(input: Rational, expected: String) throws {
        #expect(input.fancyDescription == expected)
    }
}
