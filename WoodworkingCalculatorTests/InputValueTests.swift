import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

private let formatOptions = Quantity.FormattingOptions(
    .inches,
    .init(denominator: 16),
    3,
    9,
)

private extension InputValue {
    func appending(suffix: String, allowingResultReplacement: Bool = false, trimmingSuffix: TrimmableCharacterSet? = nil) -> InputValue? {
        appending(
            suffix: suffix,
            formattingResultWith: formatOptions,
            assumeInches: false,
            allowingResultReplacement: allowingResultReplacement,
            trimmingSuffix: trimmingSuffix,
        )
    }

    func inverted() -> InputValue? {
        inverted(formattingResultWith: formatOptions, assumeInches: false)
    }
}

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct InputValueTests {
    @Test func appendFromEmpty() throws {
        var input: InputValue = .draft(.init(), nil)

        try #require(input.appending(suffix: " ") == nil) // no whitespace-only strings
        input = try #require(input.appending(suffix: "1"))
        input = try #require(input.appending(suffix: " "))
        try #require(input.appending(suffix: " ") == nil) // duplicative whitespace is ignored
        input = try #require(input.appending(suffix: "+"))
        try #require(input.appending(suffix: "+") == nil) // invalid syntax
        try #require(input.appending(suffix: "/") == nil) // still invalid syntax
        input = try #require(input.appending(suffix: " "))
        input = try #require(input.appending(suffix: "1"))

        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1 + 1")
        } else {
            Issue.record("Expected draft case")
        }
    }

    @Test func appendingToResult() throws {
        var input: InputValue = .result(EvaluationResult(actualQuantity: .real(1.0, .length), noUnitsSpecified: false))

        // would not create a legal (prefix of an) expression without replacement
        try #require(input.appending(suffix: "2") == nil)

        // okay to replace with a legal (prefix of an) expression
        input = try #require(input.appending(suffix: "2", allowingResultReplacement: true))
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "2")
        } else {
            Issue.record("Expected draft case")
        }

        // can append "+" to result
        input = .result(EvaluationResult(actualQuantity: .real(1.0, .length), noUnitsSpecified: false))
        input = try #require(input.appending(suffix: "+"))
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1in+")
        } else {
            Issue.record("Expected draft case")
        }

        // no whitespace-only strings if trying to overwrite a result
        input = .result(EvaluationResult(actualQuantity: .real(1.0, .length), noUnitsSpecified: false))
        try #require(input.appending(suffix: " ", allowingResultReplacement: true) == nil)
    }

    @Test func appendingToResultAssumingInches() throws {
        let unitless = InputValue.result(EvaluationResult(actualQuantity: .rational(rational(3, 1), .unitless), noUnitsSpecified: true))
        let appended = try #require(unitless.appending(suffix: "+", formattingResultWith: formatOptions, assumeInches: true))
        if case .draft(let prefix, _) = appended {
            #expect(prefix.value == "3in+")
        } else {
            Issue.record("Expected draft case")
        }
    }

    @Test func invertResult() throws {
        let positive = InputValue.result(EvaluationResult(actualQuantity: .rational(rational(3, 1), .length), noUnitsSpecified: false))
        let inverted = try #require(positive.inverted())
        if case .draft(let prefix, _) = inverted {
            #expect(prefix.value == "-3in")
        } else {
            Issue.record("Expected draft case")
        }

        // inverting again should remove the minus sign
        let reinverted = try #require(inverted.inverted())
        if case .draft(let prefix, _) = reinverted {
            #expect(prefix.value == "3in")
        } else {
            Issue.record("Expected draft case")
        }
    }

    @Test func invertResultAssumingInches() throws {
        let unitless = InputValue.result(EvaluationResult(actualQuantity: .rational(rational(3, 1), .unitless), noUnitsSpecified: true))
        let inverted = try #require(unitless.inverted(formattingResultWith: formatOptions, assumeInches: true))
        if case .draft(let prefix, _) = inverted {
            #expect(prefix.value == "-3in")
        } else {
            Issue.record("Expected draft case")
        }
    }

    @Test func invertDraftSingleNumber() throws {
        let positive = InputValue.draft(ValidExpressionPrefix("5")!, nil)
        let inverted = try #require(positive.inverted())
        if case .draft(let prefix, _) = inverted {
            #expect(prefix.value == "-5")
        } else {
            Issue.record("Expected draft case")
        }

        let negative = InputValue.draft(ValidExpressionPrefix("-5")!, nil)
        let reinverted = try #require(negative.inverted())
        if case .draft(let prefix, _) = reinverted {
            #expect(prefix.value == "5")
        } else {
            Issue.record("Expected draft case")
        }
    }

    @Test func invertDraftNegativeWithUnit() throws {
        let negative = InputValue.draft(ValidExpressionPrefix("-4in[2]")!, nil)
        let inverted = try #require(negative.inverted())
        if case .draft(let prefix, _) = inverted {
            #expect(prefix.value == "4in[2]")
        } else {
            Issue.record("Expected draft case")
        }
    }

    @Test func invertDraftExpressionIsNoop() {
        let expression = InputValue.draft(ValidExpressionPrefix("1 + 2")!, nil)
        #expect(expression.inverted() == nil)
    }

    @Test func appendDeletingSuffix() throws {
        var input: InputValue = .draft(ValidExpressionPrefix("1 ")!, nil)

        // sanity-check that this case doesn't work without trimmingSuffix
        try #require(input.appending(suffix: "/4") == nil)

        // works with trimmingSuffix
        input = try #require(input.appending(suffix: "/4", trimmingSuffix: .whitespaceAndFractionSlash))
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1/4")
        } else {
            Issue.record("Expected draft case")
        }

        input = .draft(ValidExpressionPrefix("1/")!, nil)

        // sanity-check that this case doesn't work without trimmingSuffix
        try #require(input.appending(suffix: "/4") == nil)

        // works with trimmingSuffix
        input = try #require(input.appending(suffix: "/4", trimmingSuffix: .whitespaceAndFractionSlash))
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1/4")
        } else {
            Issue.record("Expected draft case")
        }
    }
}
