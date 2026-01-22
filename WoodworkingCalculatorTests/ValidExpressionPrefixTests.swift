import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct ValidExpressionPrefixTests {
    @Test<[(UsCustomaryQuantity, String)]>("parse and format from UsCustomaryQuantity (inches)", arguments: [
        // .unitless
        (.real(0, .unitless), "0"),
        (.rational(rational(0, 1), .unitless), "0"),
        (.rational(rational(42, 1), .unitless), "42"),
        (.rational(rational(1, 2), .unitless), "0.5"),
        (.real(3.14159, .unitless), "3.142"),

        // .length
        (.rational(rational(0, 1), .length), "0in"),
        (.rational(rational(1, 2), .length), "1/2in"),
        (.rational(rational(1, -2), .length), "-1/2in"),
        (.rational(rational(6, 1), .length), "6in"),
        (.rational(rational(12, 1), .length), "12in"),
        (.rational(rational(48, 1), .length), "48in"),
        (.rational(rational(13, 1), .length), "13in"),
        (.rational(rational(49, 1), .length), "49in"),
        (.rational(rational(99, 2), .length), "49 1/2in"),
        (.real(0.0, .length), "0in"),
        (.real(0.5, .length), "1/2in"),
        (.real(-0.5, .length), "-1/2in"),
        (.real(15.375, .length), "15 3/8in"),

        // .area
        (.rational(rational(144, 1), .area), "144in[2]"),
        (.real(25.5, .area), "25.5in[2]"),

        // .volume
        (.rational(rational(1728, 1), .volume), "1728in[3]"),
        (.real(10.125, .volume), "10.125in[3]"),
    ]) func testInitFromInches(quantity: UsCustomaryQuantity, expected: String) throws {
        let actual = ValidExpressionPrefix(quantity, as: .inches, denominator: 64)
        #expect(actual.value == expected)
    }

    @Test<[(UsCustomaryQuantity, String)]>("parse and format from UsCustomaryQuantity (feet and inches)", arguments: [
        // .unitless
        (.real(0, .unitless), "0"),
        (.rational(rational(0, 1), .unitless), "0"),
        (.rational(rational(100, 1), .unitless), "100"),
        (.rational(rational(1, 2), .unitless), "0.5"),
        (.real(2.718, .unitless), "2.718"),

        // .length
        (.rational(rational(0, 1), .length), "0in"),
        (.rational(rational(6, 1), .length), "6in"),
        (.rational(rational(12, 1), .length), "1ft"),
        (.rational(rational(48, 1), .length), "4ft"),
        (.rational(rational(25, 2), .length), "1ft 1/2in"),
        (.rational(rational(-25, 2), .length), "-1ft 1/2in"),
        (.rational(rational(13, 1), .length), "1ft 1in"),
        (.rational(rational(49, 1), .length), "4ft 1in"),
        (.rational(rational(99, 2), .length), "4ft 1 1/2in"),
        (.real(0.0, .length), "0in"),
        (.real(12.0, .length), "1ft"),
        (.real(12.5, .length), "1ft 1/2in"),
        (.real(-12.5, .length), "-1ft 1/2in"),
        (.real(48.75, .length), "4ft 3/4in"),
        (.real(61.125, .length), "5ft 1 1/8in"),

        // .area
        (.rational(rational(288, 1), .area), "2ft[2]"),
        (.real(72.0, .area), "0.5ft[2]"),

        // .volume
        (.rational(rational(3456, 1), .volume), "2ft[3]"),
        (.real(864.0, .volume), "0.5ft[3]"),
    ]) func testInitFromFeet(quantity: UsCustomaryQuantity, expected: String) throws {
        let actual = ValidExpressionPrefix(quantity, as: .feet, denominator: 64)
        #expect(actual.value == expected)
    }

    @Test<[(String, String)]>("backspaced", arguments: [
        ("", ""),
        ("1", ""),
        ("12", "1"),
        ("12in", "12"),
        ("5ft", "5"),
        ("144in[2]", "144"),
        ("25.5ft[2]", "25.5"),
        ("1+2", "1+"),
        ("12in+5ft", "12in+5"),
        ("10in[2]×3", "10in[2]×"),
    ]) func testBackspaced(input: String, expected: String) throws {
        guard let prefix = ValidExpressionPrefix(input) else {
            Issue.record("Invalid input: \(input)")
            return
        }
        #expect(prefix.backspaced.value == expected)
    }

    @Test<[(String, String?, TrimmableCharacterSet?, String?)]>("append", arguments: [
        // simple cases
        ("", "1", nil, "1"),
        ("1", "2", nil, "12"),
        ("12", "+", nil, "12+"),

        // units
        ("5", "in[2]", nil, "5in[2]"),
        ("12", "ft", nil, "12ft"),

        // fractions and trimming
        ("1", "/2", .whitespaceAndFractionSlash, "1/2"),
        ("1/", "/2", .whitespaceAndFractionSlash, "1/2"),
        ("1 ", "/2", .whitespaceAndFractionSlash, "1/2"),
        // This isn't really the intended usage, but it's what it says on the tin.
        ("1 ", "2", .whitespaceAndFractionSlash, "12"),

        // whitespace collapsing
        ("1  ", "2", nil, "1 2"),

        // illegal results
        ("1+", "+", nil, nil),
        ("12 1", " ", nil, nil),
    ]) func testAppend(input: String, suffix: String, trimming: TrimmableCharacterSet?, expected: String?) throws {
        guard let prefix = ValidExpressionPrefix(input) else {
            Issue.record("Invalid input: \(input)")
            return
        }
        let actual = prefix.append(suffix, trimmingSuffix: trimming)
        if let expected {
            try #require(actual != nil)
            #expect(actual!.value == expected)
        } else {
            #expect(actual == nil)
        }
    }
}
