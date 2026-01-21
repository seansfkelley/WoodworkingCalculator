import Testing

@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct ValidExpressionPrefixTests {
    @Test<[(Rational, Dimension, String)]>("pretty (inches)", arguments: [
        (rational(0, 1), .length, "0in1"),
        (rational(1, 2), .length, "1/2in1"),
        (rational(1, -2), .length, "-1/2in1"),
        (rational(6, 1), .length, "6in1"),
        (rational(12, 1), .length, "12in1"),
        (rational(48, 1), .length, "48in1"),
        (rational(13, 1), .length, "13in1"),
        (rational(49, 1), .length, "49in1"),
        (rational(99, 2), .length, "49 1/2in1"),
    ]) func testFormatAsUsCustomaryInches(rational: Rational, dimension: Dimension, expected: String) throws {
        #expect(formatAsUsCustomary(rational, dimension, .inches) == expected)
    }

    @Test<[(Rational, Dimension, String)]>("pretty (feet and inches)", arguments: [
        (rational(0, 1), .length, "0in1"),
        (rational(6, 1), .length, "6in1"),
        (rational(12, 1), .length, "1ft1"),
        (rational(48, 1), .length, "4ft1"),
        (rational(25, 2), .length, "1ft1 1/2in1"),
        (rational(-25, 2), .length, "-1ft1 1/2in1"),
        (rational(13, 1), .length, "1ft1 1in1"),
        (rational(49, 1), .length, "4ft1 1in1"),
        (rational(99, 2), .length, "4ft1 1 1/2in1"),
    ]) func testFormatAsUsCustomaryFeet(rational: Rational, dimension: Dimension, expected: String) throws {
        #expect(formatAsUsCustomary(rational, dimension, .feet) == expected)
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
}
