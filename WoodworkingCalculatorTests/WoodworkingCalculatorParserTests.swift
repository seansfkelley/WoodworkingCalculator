import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct WoodworkingCalculatorParserTests {
    @Test("parseMixedNumber", arguments: [
        ("1/2", UncheckedRational(1, 2)),
        ("3 3/4", UncheckedRational(15, 4)),
        ("1  1/2", UncheckedRational(3, 2)),
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
}

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct EvaluatableCalculationTests {
    @Test<[(String, EvaluatableCalculation, Quantity)]>("from", arguments: [
        (
            "1/2",
            .rational(UncheckedRational(1, 2)),
            .rational(rational(1, 2)),
        ),
        (
            "3.5",
            .real(3.5),
            .real(3.5),
        ),
        (
            "1 + 2 × 3",
            .add(.rational(UncheckedRational(1, 1)), .multiply(.rational(UncheckedRational(2, 1)), .rational(UncheckedRational(3, 1)))),
            .rational(rational(7, 1)),
        ),
        (
            "(1 + 2) × 3",
            .multiply(.add(.rational(UncheckedRational(1, 1)), .rational(UncheckedRational(2, 1))), .rational(UncheckedRational(3, 1))),
            .rational(rational(9, 1)),
        ),
        (
            "1 + 2 × 3 ÷ 4",
            .add(.rational(UncheckedRational(1, 1)), .divide(.multiply(.rational(UncheckedRational(2, 1)), .rational(UncheckedRational(3, 1))), .rational(UncheckedRational(4, 1)))),
            .rational(rational(5, 2)),
        ),
        (
            "1' 3\" × 3.2",
            .multiply(.rational(UncheckedRational(15, 1)), .real(3.2)),
            .real(48.0),
        ),
        (
            "-1",
            .subtract(.rational(UncheckedRational(0, 1)), .rational(UncheckedRational(1, 1))),
            .rational(rational(-1, 1)),
        ),
        (
            "1 -- 2",
            .subtract(.rational(UncheckedRational(1, 1)), .subtract(.rational(UncheckedRational(0, 1)), .rational(UncheckedRational(2, 1)))),
            .rational(rational(3, 1)),
        )
    ]) func from(input: String, expectedEvaluatable: EvaluatableCalculation, expectedResult: Quantity) throws {
        let evaluatable = EvaluatableCalculation.from(input)
        // FIXME: I would like to do straight equality, but I don't want to give UncheckedRational
        // an equality definition since it does not reduce to lowest terms, etc.
        #expect(evaluatable?.description == expectedEvaluatable.description)
        #expect(evaluatable!.evaluate() == .success(expectedResult))
    }
    
    @Test("from (nil)", arguments: [
        "1//2",
        "1++",
        "1 1",
        "1--",
        "1*2",
    ]) func fromNil(input: String) throws {
        #expect(EvaluatableCalculation.from(input) == nil)
    }
    
    @Test("isValidPrefix", arguments: [
        "1",
        "1.",
        "1 1",
        "1 1/",
        "1+",
        "1+2-3/4×",
        "1+1",
        "1+-",
        "1'",
        "1'1",
        "1'1\"",
        "1' ",
        "1\" ",
        "1.",
        ".",
        "1.1",
        " ",
        "-",
    ]) func isValidPrefix(input: String) throws {
        #expect(EvaluatableCalculation.isValidPrefix(input))
    }
    
    @Test("!isValidPrefix", arguments: [
        "+",
        "'",
        "\"",
        "1++",
        "1''",
        "..",
        "--",
    ]) func notIsValidPrefix(input: String) throws {
        #expect(!EvaluatableCalculation.isValidPrefix(input))
    }
}
