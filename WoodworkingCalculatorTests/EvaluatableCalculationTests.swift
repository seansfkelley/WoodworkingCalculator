import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct EvaluatableCalculationTests {
    @Test<[(String, EvaluatableCalculation, Result<Quantity, EvaluationError>)]>("from", arguments: [
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
            "3ft",
            .rational(UncheckedRational(36, 1), .length),
            .success(.rational(rational(36, 1), .length)),
        ),
        (
            "6in",
            .rational(UncheckedRational(6, 1), .length),
            .success(.rational(rational(6, 1), .length)),
        ),
        (
            "5mm",
            .real(5 / 25.4, .length),
            .success(.real(5 / 25.4, .length)),
        ),
        (
            "10cm",
            .real(10 / 2.54, .length),
            .success(.real(10 / 2.54, .length)),
        ),
        (
            "2m",
            .real(2 / 0.0254, .length),
            .success(.real(2 / 0.0254, .length)),
        ),
        (
            "3ft[2]",
            .rational(UncheckedRational(432, 1), .area),
            .success(.rational(rational(432, 1), .area)),
        ),
        (
            "2.5in[2]",
            .real(2.5, .area),
            .success(.real(2.5, .area)),
        ),
        (
            "2m[2]",
            .real(2 / 0.00064516, .area),
            .success(.real(2 / 0.00064516, .area)),
        ),
        (
            "10cm[3]",
            .real(10 / 16.387064, .volume),
            .success(.real(10 / 16.387064, .volume)),
        ),
        (
            "1/2in[3]",
            .rational(UncheckedRational(1, 2), .volume),
            .success(.rational(rational(1, 2), .volume)),
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
            "1ft 3in × 3.2",
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
            "1ft + 1in",
            .add(
                .rational(UncheckedRational(12, 1), .length),
                .rational(UncheckedRational(1, 1), .length),
            ),
            .success(.rational(rational(13, 1), .length)),
        ),
        (
            "1in + 2in[2]",
            .add(
                .rational(UncheckedRational(1, 1), .length),
                .rational(UncheckedRational(2, 1), .area),
            ),
            .failure(.incompatibleDimensions)
        ),
        (
            "1 ÷ 1ft",
            .divide(
                .rational(UncheckedRational(1, 1), .unitless),
                .rational(UncheckedRational(12, 1), .length),
            ),
            .failure(.negativeDimension)
        ),
        (
            "2 × 3ft",
            .multiply(
                .rational(UncheckedRational(2, 1), .unitless),
                .rational(UncheckedRational(36, 1), .length),
            ),
            .success(.rational(rational(72, 1), .length)),
        ),
    ]) func from(input: String, expectedEvaluatable: EvaluatableCalculation, expectedResult: Result<Quantity, EvaluationError>) throws {
        let evaluatable = EvaluatableCalculation.from(input)
        // FIXME: I would like to do straight equality, but I don't want to give UncheckedRational
        // an equality definition since it does not reduce to lowest terms, etc.
        #expect(evaluatable?.description == expectedEvaluatable.description)
        
        let actualResult = evaluatable!.evaluate()

        switch (actualResult, expectedResult) {
        case (.success(.real(let actualValue, let actualDim)), .success(.real(let expectedValue, let expectedDim))):
            #expect(actualDim == expectedDim)
            #expect(actualValue.isApproximatelyEqual(to: expectedValue, relativeTolerance: 0.000001))
        default:
            #expect(actualResult == expectedResult)
        }
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
        "1ft",
        "1ft1",
        "1ft1in",
        "1ft ",
        "1in ",
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
        "1*", // not the correct spelling of multiplication
        "1'", // not the correct internal representation
        "1\"", // not the correct internal representation
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

    @Test("allDimensionsAreUnitless (true)", arguments: [
        "1",
        "3.5 + 1/2",
        "1 + 2 × 3 ÷ 4",
        "((1 + 1) × (2 - 1))",
    ]) func allDimensionsAreUnitlessTrue(input: String) throws {
        let evaluatable = try #require(EvaluatableCalculation.from(input))
        #expect(evaluatable.allDimensionsAreUnitless == true)
    }

    @Test("allDimensionsAreUnitless (false)", arguments: [
        "1ft",
        "1ft + 1in",
        "1ft 3in × 3.2",
        "3ft[2]",
        "1/2in[3]",
        "1in ÷ 1in", // the result is unitless, but the input is not!
    ]) func allDimensionsAreUnitlessFalse(input: String) throws {
        let evaluatable = try #require(EvaluatableCalculation.from(input))
        #expect(evaluatable.allDimensionsAreUnitless == false)
    }
}
