import Testing
@testable import WoodworkingCalculator

struct WoodworkingCalculatorParserTests {
    @Test("parseMixedNumber", arguments: [
        ("1/2", Rational(1, 2)),
        ("3-3/4", Rational(15, 4)),
        ("3 3/4", Rational(15, 4)),
        ("3   -  3/4", Rational(15, 4)),
        ("3--3/4", nil),
        ("1 /2", nil),
        ("1/ 2", nil),
        ("1 / 2", nil),
    ]) func testParseMixedNumber(input: String, expected: Rational?) throws {
        let actual = parseMixedNumber(input)
        if expected == nil {
            #expect(actual == nil)
        } else if actual == nil {
            Issue.record("Unexpected nil result")
        } else {
            #expect(actual!.1 == .MixedNumber)
            if case .rational(let actual) = actual!.0 {
                #expect(actual == expected)
            } else {
                Issue.record("Expected parsed value to be a .rational but it was not")
            }
        }
    }
    
    @Test("formatAsUsCustomary", arguments: [
        (Rational(0, 1), "0\""),
        (Rational(12, 1), "1'"),
        (Rational(48, 1), "4'"),
        (Rational(13, 1), "1' 1\""),
        (Rational(49, 1), "4' 1\""),
        (Rational(99, 2), "4' 1 1/2\""),
    ]) func testFormatAsUsCustomary(input: Rational, expected: String) throws {
        #expect(formatAsUsCustomary(input) == expected)
    }
    
    // Serialized: Citron is not thread-safe.
    @Test("isValidPrefix", .serialized, arguments: [
        "1",
        "1.",
        "1 1",
        "1 1/",
        "1+",
        "1+2-3/4*",
        "1+1",
    ]) func testIsValidPrefix(input: String) throws {
        #expect(isValidPrefix(input))
    }
}
