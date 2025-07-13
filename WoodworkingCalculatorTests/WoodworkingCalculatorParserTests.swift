import Testing
@testable import WoodworkingCalculator

struct WoodworkingCalculatorParserTests {
    @Test("parseMixedNumber", arguments: [
        ("1/2", Rational(1, 2)),
        ("3 3/4", Rational(15, 4)),
        ("1  1/2", Rational(3, 2)),
        ("1 /2", nil),
        ("1/ 2", nil),
        ("1 / 2", nil),
        ("3-3/4", nil),
        ("3--3/4", nil),
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
}

struct EvaluatableCalculationTests {
    // Serialized: Citron is not thread-safe.
    @Test("from", .serialized, arguments: [
        ("1/2", CalculationResult.rational(Rational(1, 2))),
        ("3.5", CalculationResult.real(3.5)),
        ("1 + 2 * 3", CalculationResult.rational(Rational(7, 1))),
        ("(1 + 2) * 3", CalculationResult.rational(Rational(9, 1))),
    ]) func from(_ input: (String, CalculationResult)) throws {
        #expect(EvaluatableCalculation.from(input.0)?.evaluate() == input.1)
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
        "1'",
        "1'1",
        "1'1\"",
        "1' ",
        "1\" ",
        "1.",
        ".",
        "1.1",
        " ",
    ]) func isValidPrefix(input: String) throws {
        #expect(EvaluatableCalculation.isValidPrefix(input))
    }
    
    // Serialized: Citron is not thread-safe.
    @Test("!isValidPrefix", .serialized, arguments: [
        "+",
        "'",
        "\"",
        "1++",
        "1+-",
        "1''",
        "..",
    ]) func notIsValidPrefix(input: String) throws {
        #expect(!EvaluatableCalculation.isValidPrefix(input))
    }
}
