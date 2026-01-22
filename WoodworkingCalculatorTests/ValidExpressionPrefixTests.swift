import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct ValidExpressionPrefixTests {
    @Test<[(UsCustomaryQuantity, String, String)]>("parse and format from UsCustomaryQuantity (inches)", arguments: [
        // .unitless
        (.rational(rational(42, 1), .unitless), "42", "42"),
        (.real(3.14159, .unitless), "3.142", "3.142"),

        // .length
        (.rational(rational(0, 1), .length), "0in", "0\""),
        (.rational(rational(1, 2), .length), "1/2in", "¹⁄₂\""),
        (.rational(rational(1, -2), .length), "-1/2in", "-¹⁄₂\""),
        (.rational(rational(6, 1), .length), "6in", "6\""),
        (.rational(rational(12, 1), .length), "12in", "12\""),
        (.rational(rational(48, 1), .length), "48in", "48\""),
        (.rational(rational(13, 1), .length), "13in", "13\""),
        (.rational(rational(49, 1), .length), "49in", "49\""),
        (.rational(rational(99, 2), .length), "49 1/2in", "49 ¹⁄₂\""),
        (.real(0.0, .length), "0in", "0\""),
        (.real(0.5, .length), "1/2in", "¹⁄₂\""),
        (.real(-0.5, .length), "-1/2in", "-¹⁄₂\""),
        (.real(15.375, .length), "15 3/8in", "15 ³⁄₈\""),

        // .area
        (.rational(rational(144, 1), .area), "144in[2]", "144in²"),
        (.real(25.5, .area), "25.5in[2]", "25.5in²"),

        // .volume
        (.rational(rational(1728, 1), .volume), "1728in[3]", "1728in³"),
        (.real(10.125, .volume), "10.125in[3]", "10.125in³"),
    ]) func testFormatAsUsCustomaryInches(quantity: UsCustomaryQuantity, raw: String, pretty: String) throws {
        let actual = ValidExpressionPrefix(quantity, as: .inches, denominator: 64)
        #expect(actual.value == raw)
        #expect(actual.pretty == pretty)
    }

    @Test<[(UsCustomaryQuantity, String, String)]>("parse and format from UsCustomaryQuantity (feet and inches)", arguments: [
        // .unitless
        (.rational(rational(100, 1), .unitless), "100", "100"),
        (.real(2.718, .unitless), "2.718", "2.718"),

        // .length
        (.rational(rational(0, 1), .length), "0in", "0\""),
        (.rational(rational(6, 1), .length), "6in", "6\""),
        (.rational(rational(12, 1), .length), "1ft", "1'"),
        (.rational(rational(48, 1), .length), "4ft", "4'"),
        (.rational(rational(25, 2), .length), "1ft 1/2in", "1' ¹⁄₂\""),
        (.rational(rational(-25, 2), .length), "-1ft 1/2in", "-1' ¹⁄₂\""),
        (.rational(rational(13, 1), .length), "1ft 1in", "1' 1\""),
        (.rational(rational(49, 1), .length), "4ft 1in", "4' 1\""),
        (.rational(rational(99, 2), .length), "4ft 1 1/2in", "4' 1 ¹⁄₂\""),
        (.real(0.0, .length), "0in", "0\""),
        (.real(12.0, .length), "1ft", "1'"),
        (.real(12.5, .length), "1ft 1/2in", "1' ¹⁄₂\""),
        (.real(-12.5, .length), "-1ft 1/2in", "-1' ¹⁄₂\""),
        (.real(48.75, .length), "4ft 3/4in", "4' ³⁄₄\""),
        (.real(61.125, .length), "5ft 1 1/8in", "5' 1 ¹⁄₈\""),

        // .area
        (.rational(rational(288, 1), .area), "2ft[2]", "2ft²"),
        (.real(72.0, .area), "0.5ft[2]", "0.5ft²"),

        // .volume
        (.rational(rational(3456, 1), .volume), "2ft[3]", "2ft³"),
        (.real(864.0, .volume), "0.5ft[3]", "0.5ft³"),
    ]) func testFormatAsUsCustomaryFeet(quantity: UsCustomaryQuantity, raw: String, pretty: String) throws {
        let actual = ValidExpressionPrefix(quantity, as: .feet, denominator: 64)
        #expect(actual.value == raw)
        #expect(actual.pretty == pretty)
    }
}
