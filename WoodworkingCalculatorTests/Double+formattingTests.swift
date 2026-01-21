import Testing
@testable import Wood_Calc

struct DoubleFormattingTests {
    @Test("formatAsDecimal", arguments: [
        (0.123, 0, "0"),
        (0.12345, 2, "0.12"),
        (0.1001, 3, "0.1"),
        (0.04, 1, "0"),
        (0.05, 1, "0.1"),
        (0.06, 1, "0.1"),
        (1000, 0, "1000"),
    ]) func testFormatAsDecimal(number: Double, precision: Int, expected: String) throws {
        #expect(number.formatAsDecimal(toPlaces: precision) == expected)
    }
}
