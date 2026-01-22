import Testing
@testable import Wood_Calc

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct ValidExpressionPrefixTests {
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
