import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct ValidExpressionPrefixTests {
    @Test<[(UsCustomaryQuantity, String, String)]>("parse and format from Quantity (inches)", arguments: [
        (.rational(rational(0, 1), .length), "0in", "0\""),
        (.rational(rational(1, 2), .length), "1/2in", "¹⁄₂\""),
        (.rational(rational(1, -2), .length), "-1/2in", "-¹⁄₂\""),
        (.rational(rational(6, 1), .length), "6in", "6\""),
        (.rational(rational(12, 1), .length), "12in", "12\""),
        (.rational(rational(48, 1), .length), "48in", "48\""),
        (.rational(rational(13, 1), .length), "13in", "13\""),
        (.rational(rational(49, 1), .length), "49in", "49\""),
        (.rational(rational(99, 2), .length), "49 1/2in", "49 ¹⁄₂\""),
    ]) func testFormatAsUsCustomaryInches(quantity: UsCustomaryQuantity, raw: String, pretty: String) throws {
        let actual = ValidExpressionPrefix(quantity, as: .inches, denominator: 64)
        #expect(actual.value == raw)
        #expect(actual.pretty == pretty)
    }

    @Test<[(UsCustomaryQuantity, String, String)]>("parse and format from Quantity (feet and inches)", arguments: [
        (.rational(rational(0, 1), .length), "0in", "0\""),
        (.rational(rational(6, 1), .length), "6in", "6\""),
        (.rational(rational(12, 1), .length), "1ft", "1'"),
        (.rational(rational(48, 1), .length), "4ft", "4'"),
        (.rational(rational(25, 2), .length), "1ft 1/2in", "1' ¹⁄₂\""),
        (.rational(rational(-25, 2), .length), "-1ft 1/2in", "-1' ¹⁄₂\""),
        (.rational(rational(13, 1), .length), "1ft 1in", "1' 1\""),
        (.rational(rational(49, 1), .length), "4ft 1in", "4' 1\""),
        (.rational(rational(99, 2), .length), "4ft 1 1/2in", "4' 1 ¹⁄₂\""),
    ]) func testFormatAsUsCustomaryFeet(quantity: UsCustomaryQuantity, raw: String, pretty: String) throws {
        let actual = ValidExpressionPrefix(quantity, as: .feet, denominator: 64)
        #expect(actual.value == raw)
        #expect(actual.pretty == pretty)
    }
}
