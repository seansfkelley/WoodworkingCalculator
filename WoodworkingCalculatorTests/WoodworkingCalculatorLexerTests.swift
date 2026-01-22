import Testing
@testable import Wood_Calc

struct WoodworkingCalculatorLexerTests {
    @Test("parseMixedNumber", arguments: [
        ("1/2", UncheckedRational(1, 2)),
        ("3 3/4", UncheckedRational(15, 4)),
        ("1  1/2", UncheckedRational(3, 2)),
        ("1/0", UncheckedRational(1, 0)),
        ("", nil),
        ("1 /2", nil),
        ("1/ 2", nil),
        ("1 / 2", nil),
        ("3-3/4", nil),
        ("3--3/4", nil),
        ("1111111111111111111111111/2", nil),
        ("1/1111111111111111111111111", nil),
        ("1111111111111111111111111 1/2", nil),
    ]) func testParseMixedNumber(input: String, expected: UncheckedRational?) throws {
        let actual = parseMixedNumber(input)
        if expected == nil {
            #expect(actual == nil)
        } else if actual == nil {
            Issue.record("Unexpected nil result")
        } else {
            #expect(actual!.1 == .MixedNumber)
            if case .rational(let actual) = actual!.0 {
                #expect(actual.num == expected!.num)
                #expect(actual.den == expected!.den)
            } else {
                Issue.record("Expected parsed value to be a .rational but it was not")
            }
        }
    }

    @Test("parseReal", arguments: [
        ("1.0", 1.0),
        ("0.1", 0.1),
        ("123.456", 123.456),
        ("1", nil),
        ("123", nil),
        ("1.", nil),
        ("", nil),
        (" 1", nil),
        ("x", nil),
        ("1111111111111111111111111.0", nil)
    ]) func testParseReal(input: String, expected: Double?) throws {
        let actual = parseReal(input)
        if expected == nil {
            #expect(actual == nil)
        } else if actual == nil {
            Issue.record("Unexpected nil result")
        } else {
            #expect(actual!.1 == .Real)
            if case .real(let actual) = actual!.0 {
                #expect(actual == expected)
            } else {
                Issue.record("Expected parsed value to be a .real but it was not")
            }
        }
    }

    @Test("parseInteger", arguments: [
        ("1", 1),
        ("123", 123),
        ("1.", 1),
        ("", nil),
        ("1.0", nil),
        (" 1", nil),
        ("x", nil),
        ("1111111111111111111111111", nil),
    ]) func testParseInteger(input: String, expected: Int?) throws {
        let actual = parseInteger(input)
        if expected == nil {
            #expect(actual == nil)
        } else if actual == nil {
            Issue.record("Unexpected nil result")
        } else {
            #expect(actual!.1 == .Integer)
            if case .integer(let actual) = actual!.0 {
                #expect(actual == expected)
            } else {
                Issue.record("Expected parsed value to be an .integer but it was not")
            }
        }
    }

    @Test("parseDimension", arguments: [
        ("[0]", 0),
        ("[1]", 1),
        ("[123]", 123),
        ("[1111111111111111111111111]", nil),
        ("[]", nil),
        ("[", nil),
        ("]", nil),
        ("1", nil),
        ("[1", nil),
        ("1]", nil),
        ("[ 1]", nil),
        ("[1 ]", nil),
        ("[a]", nil),
        ("[-1]", nil),
        ("[1.0]", nil),
        ("[1/2]", nil),
        ("", nil),
    ]) func testParseDimension(input: String, expected: UInt?) throws {
        let actual = parseDimension(input)
        if expected == nil {
            #expect(actual == nil)
        } else if actual == nil {
            Issue.record("Unexpected nil result")
        } else {
            #expect(actual!.1 == .Dimension)
            if case .dimension(let actual) = actual!.0 {
                #expect(actual.value == expected)
            } else {
                Issue.record("Expected parsed value to be a .dimension but it was not")
            }
        }
    }
}
