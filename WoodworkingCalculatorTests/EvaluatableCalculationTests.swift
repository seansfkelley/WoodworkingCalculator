import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct EvaluatableCalculationTests {
    @Test<[(String, EvaluatableCalculation, Result<UsCustomaryQuantity, EvaluationError>)]>("from", arguments: [
        (
            "1/2",
            .rational(UncheckedRational(1, 2), .unitless),
            .success(.rational(rational(1, 2), .unitless)),
        ),
        (
            "3.5",
            .real(3.5, .unitless),
            .success(.real(3.5, .unitless)),
        ),
        (
            "1 + 2 × 3",
            .add(
                .rational(UncheckedRational(1, 1), .unitless),
                .multiply(
                    .rational(UncheckedRational(2, 1), .unitless),
                    .rational(UncheckedRational(3, 1), .unitless),
                )
            ),
            .success(.rational(rational(7, 1), .unitless)),
        ),
        (
            "(1 + 2) × 3",
            .multiply(
                .add(
                    .rational(UncheckedRational(1, 1), .unitless),
                    .rational(UncheckedRational(2, 1), .unitless),
                ),
                .rational(UncheckedRational(3, 1), .unitless),
            ),
            .success(.rational(rational(9, 1), .unitless)),
        ),
        (
            "1 + 2 × 3 ÷ 4",
            .add(
                .rational(UncheckedRational(1, 1), .unitless),
                .divide(
                    .multiply(
                        .rational(UncheckedRational(2, 1), .unitless),
                        .rational(UncheckedRational(3, 1), .unitless),
                    ),
                    .rational(UncheckedRational(4, 1), .unitless),
                )
            ),
            .success(.rational(rational(5, 2), .unitless)),
        ),
        (
            "1' 3\" × 3.2",
            .multiply(
                .rational(UncheckedRational(15, 1), .length),
                .real(3.2, .unitless),
            ),
            .success(.real(48.0, .length)),
        ),
        (
            "-1",
            .subtract(
                .rational(UncheckedRational(0, 1), .unitless),
                .rational(UncheckedRational(1, 1), .unitless),
            ),
            .success(.rational(rational(-1, 1), .unitless)),
        ),
        (
            "1 -- 2",
            .subtract(
                .rational(UncheckedRational(1, 1), .unitless),
                .subtract(
                    .rational(UncheckedRational(0, 1), .unitless),
                    .rational(UncheckedRational(2, 1), .unitless),
                )
            ),
            .success(.rational(rational(3, 1), .unitless)),
        ),
        (
            "1/0",
            .rational(UncheckedRational(1, 0), .unitless),
            .failure(.divisionByZero)
        ),
        (
            "1 ÷ 0",
            .divide(
                .rational(UncheckedRational(1, 1), .unitless),
                .rational(UncheckedRational(0, 1), .unitless),
            ),
            .failure(.divisionByZero)
        ),
        (
            "1 ÷ (1 - 1)",
            .divide(
                .rational(UncheckedRational(1, 1), .unitless),
                .subtract(
                    .rational(UncheckedRational(1, 1), .unitless),
                    .rational(UncheckedRational(1, 1), .unitless),
                )
            ),
            .failure(.divisionByZero)
        ),
        (
            "(1)",
            .rational(UncheckedRational(1, 1), .unitless),
            .success(.rational(rational(1, 1), .unitless)),
        ),
        (
            "(1 + 2",
            .add(
                .rational(UncheckedRational(1, 1), .unitless),
                .rational(UncheckedRational(2, 1), .unitless),
            ),
            .success(.rational(rational(3, 1), .unitless)),
        ),
        (
            "((((1 + 1) + 1",
            .add(
                .add(
                    .rational(UncheckedRational(1, 1), .unitless),
                    .rational(UncheckedRational(1, 1), .unitless),
                ),
                .rational(UncheckedRational(1, 1), .unitless),
            ),
            .success(.rational(rational(3, 1), .unitless)),
        ),
        (
            "10cm",
            .real(10.0 / 2.54, .unitless),
            .success(.real(10.0 / 2.54, .unitless)),
        ),
    ]) func from(input: String, expectedEvaluatable: EvaluatableCalculation, expectedResult: Result<UsCustomaryQuantity, EvaluationError>) throws {
        let evaluatable = EvaluatableCalculation.from(input)
        // FIXME: I would like to do straight equality, but I don't want to give UncheckedRational
        // an equality definition since it does not reduce to lowest terms, etc.
        #expect(evaluatable?.description == expectedEvaluatable.description)
        #expect(evaluatable!.evaluate() == expectedResult)
    }

    @Test("from (nil)", arguments: [
        "1+",
        "1//2",
        "1++",
        "1 1",
        "1--",
        "1*2", // not the right character for multiplication
        "()",
        ")",
        "(1+",
        "1 / (1 + 1)", // slash is for fractions, not division
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
        "(",
        "(1",
        "1+(",
        "(1+",
        "(1)",
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
        "()",
        ")",
    ]) func notIsValidPrefix(input: String) throws {
        #expect(!EvaluatableCalculation.isValidPrefix(input))
    }

    @Test("countMissingTrailingParens", arguments: [
        ("", 0),
        ("(1)", 0),
        ("(1)+(2)", 0),
        ("(", 1),
        ("((", 2),
        ("(1+2", 1),
        ("(1+(2", 2),
        (")", -1),
        ("))", -2),
        ("(1))", -1),
    ]) func countMissingTrailingParens(input: String, expected: Int) throws {
        #expect(EvaluatableCalculation.countMissingTrailingParens(input) == expected)
    }
}
