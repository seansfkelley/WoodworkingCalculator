import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct InputValueTests {
    let formatOptions = Quantity.FormattingOptions(
        .inches,
        .init(denominator: 16),
        3,
        9,
    )

    @Test func emptyDraftHasNoError() {
        let input = InputValue.draft(.init(), nil)
        #expect(input.error == nil)
    }

    @Test func forwardsDraftError() {
        let input = InputValue.draft(ValidExpressionPrefix("1/0")!, .divisionByZero)
        #expect(input.error == .divisionByZero)
    }

    @Test func resultHasNoError() {
        let input = InputValue.result(.real(1.0, .length))
        #expect(input.error == nil)
    }

    @Test func append() throws {
        var input: InputValue? = .draft(.init(), nil)

        try #require(input!.appending(suffix: " ", formattingResultWith: formatOptions) == nil) // no whitespace-only strings
        input = input!.appending(suffix: "1", formattingResultWith: formatOptions)
        try #require(input != nil)
        input = input!.appending(suffix: " ", formattingResultWith: formatOptions)
        try #require(input != nil)
        try #require(input!.appending(suffix: " ", formattingResultWith: formatOptions) == nil) // duplicative whitespace is ignored
        input = input!.appending(suffix: "+", formattingResultWith: formatOptions)
        try #require(input != nil)
        try #require(input!.appending(suffix: "+", formattingResultWith: formatOptions) == nil) // invalid syntax
        try #require(input!.appending(suffix: "/", formattingResultWith: formatOptions) == nil) // still invalid syntax
        input = input!.appending(suffix: " ", formattingResultWith: formatOptions)
        try #require(input != nil)
        input = input!.appending(suffix: "1", formattingResultWith: formatOptions)
        try #require(input != nil)
        
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1 + 1")
        } else {
            Issue.record("Expected draft case")
        }
    }

    @Test func appendingToResult() throws {
        var input: InputValue? = .result(.real(1.0, .length))
        
        // would not create a legal (prefix of an) expression without replacement
        try #require(input!.appending(suffix: "2", formattingResultWith: formatOptions) == nil)
        
        // okay to replace with a legal (prefix of an) expression
        input = input!.appending(suffix: "2", formattingResultWith: formatOptions, allowingResultReplacement: true)
        try #require(input != nil)
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "2")
        } else {
            Issue.record("Expected draft case")
        }
        
        // can append "+" to result
        input = .result(.real(1.0, .length))
        input = input!.appending(suffix: "+", formattingResultWith: formatOptions)
        try #require(input != nil)
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1in+")
        } else {
            Issue.record("Expected draft case")
        }
        
        // no whitespace-only strings if trying to overwrite a result
        input = .result(.real(1.0, .length))
        try #require(input!.appending(suffix: " ", formattingResultWith: formatOptions, allowingResultReplacement: true) == nil)
    }

    @Test func appendDeletingSuffix() throws {
        var input: InputValue? = .draft(ValidExpressionPrefix("1 ")!, nil)
        
        // sanity-check that this case doesn't work without trimmingSuffix
        try #require(input!.appending(suffix: "/4", formattingResultWith: formatOptions) == nil)
        
        // works with trimmingSuffix
        input = input!.appending(suffix: "/4", formattingResultWith: formatOptions, trimmingSuffix: .whitespaceAndFractionSlash)
        try #require(input != nil)
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1/4")
        } else {
            Issue.record("Expected draft case")
        }
        
        input = .draft(ValidExpressionPrefix("1/")!, nil)
        
        // sanity-check that this case doesn't work without trimmingSuffix
        try #require(input!.appending(suffix: "/4", formattingResultWith: formatOptions) == nil)
        
        // works with trimmingSuffix
        input = input!.appending(suffix: "/4", formattingResultWith: formatOptions, trimmingSuffix: .whitespaceAndFractionSlash)
        try #require(input != nil)
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1/4")
        } else {
            Issue.record("Expected draft case")
        }
    }

    @Test<[(InputValue, BackspaceOperation)]>(arguments: [
        (.result(.real(1.0, .length)), .clear),
        (.result(.rational(rational(1, 2), .length)), .clear),
        (.draft(.init("")!, nil), .draft(.init("")!)),
        (.draft(.init("1+1")!, nil), .draft(.init("1+")!)),
        (.draft(.init("1 ")!, nil), .draft(.init("1")!)),
        (.draft(.init("1/0")!, .divisionByZero), .draft(.init("1/")!)),
        (.draft(.init("1m")!, nil), .draft(.init("1")!)),
        (.draft(.init("1cm")!, nil), .draft(.init("1")!)),
        (.draft(.init("1mm")!, nil), .draft(.init("1")!)),
    ]) func backspaced(input: InputValue, expected: BackspaceOperation) {
        #expect(input.backspaced == expected)
    }
}
