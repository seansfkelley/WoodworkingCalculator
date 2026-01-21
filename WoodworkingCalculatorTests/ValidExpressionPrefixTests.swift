import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct ValidExpressionPrefixTests {
    @Test<[(Quantity, String, String)]>("parse and format from Quantity (inches)", arguments: [
        (.rational(rational(0, 1), .length), "0in1", "0\""),
        (.rational(rational(1, 2), .length), "1/2in1", "¹⁄₂\""),
        (.rational(rational(1, -2), .length), "-1/2in1", "-¹⁄₂\""),
        (.rational(rational(6, 1), .length), "6in1", "6\""),
        (.rational(rational(12, 1), .length), "12in1", "12\""),
        (.rational(rational(48, 1), .length), "48in1", "48\""),
        (.rational(rational(13, 1), .length), "13in1", "13\""),
        (.rational(rational(49, 1), .length), "49in1", "49\""),
        (.rational(rational(99, 2), .length), "49 1/2in1", "49 ¹⁄₂\""),
    ]) func testFormatAsUsCustomaryInches(quantity: Quantity, raw: String, pretty: String) throws {
        let actual = ValidExpressionPrefix(quantity, as: .inches)
        #expect(actual.value == raw)
        #expect(actual.pretty == pretty)
    }

    @Test<[(Quantity, String, String)]>("parse and format from Quantity (feet and inches)", arguments: [
        (.rational(rational(0, 1), .length), "0in1", "0\""),
        (.rational(rational(6, 1), .length), "6in1", "6\""),
        (.rational(rational(12, 1), .length), "1ft1", "1'"),
        (.rational(rational(48, 1), .length), "4ft1", "4'"),
        (.rational(rational(25, 2), .length), "1ft1 1/2in1", "1' ¹⁄₂\""),
        (.rational(rational(-25, 2), .length), "-1ft1 1/2in1", "-1' ¹⁄₂\""),
        (.rational(rational(13, 1), .length), "1ft1 1in1", "1' 1\""),
        (.rational(rational(49, 1), .length), "4ft1 1in1", "4' 1\""),
        (.rational(rational(99, 2), .length), "4ft1 1 1/2in1", "4' 1 ¹⁄₂\""),
    ]) func testFormatAsUsCustomaryFeet(quantity: Quantity, raw: String, pretty: String) throws {
        let actual = ValidExpressionPrefix(quantity, as: .feet)
        #expect(actual.value == raw)
        #expect(actual.pretty == pretty)
    }
}
