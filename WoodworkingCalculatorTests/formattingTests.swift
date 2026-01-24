import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

@Suite
struct FormattingTests {
    @Test<[(Rational, String, String)]>("Rational.formatInches", arguments: [
        (rational(0, 1), "0in", "0in"),
        (rational(1, 2), "1/2in", "1/2in"),
        (rational(1, -2), "-1/2in", "-1/2in"),
        (rational(6, 1), "6in", "6in"),
        (rational(12, 1), "12in", "1ft"),
        (rational(25, 2), "12 1/2in", "1ft 1/2in"),
        (rational(27, 2), "13 1/2in", "1ft 1 1/2in"),
        (rational(48, 1), "48in", "4ft"),
        (rational(49, 1), "49in", "4ft 1in"),
    ])
    func testRationalFormatInches(input: Rational, inches: String, feet: String) {
        #expect(input.formatInches(as: .inches) == inches)
        #expect(input.formatInches(as: .feet) == feet)
    }

    @Test<[(Double, Dimension, String, String)]>("Double.formatInches", arguments: [
        (0, .unitless, "0", "0"),
        (2.718, .unitless, "2.718", "2.718"),
        (15, .unitless, "15", "15"),
        (0.0, .length, "0in", "0ft"),
        (0.5, .length, "0.5in", "0.042ft"),
        (-0.5, .length, "-0.5in", "-0.042ft"),
        (12.0, .length, "12in", "1ft"),
        (12.5, .length, "12.5in", "1.042ft"),
        (15.375, .length, "15.375in", "1.281ft"),
        (72.0, .area, "72in[2]", "0.5ft[2]"),
        (864.0, .volume, "864in[3]", "0.5ft[3]"),
    ])
    func testFormatInches(input: Double, dimension: Dimension, inches: String, feet: String) {
        #expect(input.formatInches(as: .inches, of: dimension, toPlaces: 3) == inches)
        #expect(input.formatInches(as: .feet, of: dimension, toPlaces: 3) == feet)
    }

    @Test<[(String, String)]>("String.withPrettyNumbers", arguments: [
        ("42", "42"),
        ("3.142", "3.142"),
        ("in", "\""),
        ("ft", "'"),
        ("mm", "mm"),
        ("cm", "cm"),
        ("m", "m"),
        ("0in", "0\""),
        ("1/2in", "¹⁄₂\""),
        ("-1/2in", "-¹⁄₂\""),
        ("12in", "12\""),
        ("1ft", "1'"),
        ("15 3/8in", "15\u{2002}³⁄₈\""),
        ("144in[2]", "144in²"),
        ("25.5in[2]", "25.5in²"),
        ("1728ft[3]", "1728ft³"),
        ("3/", "³⁄ "), // note the trailing space -- the fraction slash gets cut off without a "denominator"
        ("12 3/", "12\u{2002}³⁄ "), // note the trailing space again
        ("12 ", "12\u{2002}"), // this space might not end up as a mixed number but we widen it for visuals anyway
        ("4ft 5", "4' 5"),
        ("12in+3/4in", "12\"+³⁄₄\""),
        ("5ft 3in×2", "5' 3\"×2"),
        ("(1/2in+3/4in)×3", "(¹⁄₂\"+³⁄₄\")×3"),
        ("3 1/2in×4 3/8in", "3\u{2002}¹⁄₂\"×4\u{2002}³⁄₈\""),
    ]) func testWithPrettyNumbers(input: String, expected: String) throws {
        #expect(input.withPrettyNumbers == expected)
    }
}
