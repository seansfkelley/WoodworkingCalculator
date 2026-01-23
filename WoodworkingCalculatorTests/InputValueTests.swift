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

    @Test func appendFromEmpty() throws {
        var input: InputValue? = .draft(.init(), nil)

        try #require(input!.appending(suffix: " ", formattingResultWith: formatOptions) == nil) // no whitespace-only strings
        input = try #require(input!.appending(suffix: "1", formattingResultWith: formatOptions))
        input = try #require(input!.appending(suffix: " ", formattingResultWith: formatOptions))
        try #require(input!.appending(suffix: " ", formattingResultWith: formatOptions) == nil) // duplicative whitespace is ignored
        input = try #require(input!.appending(suffix: "+", formattingResultWith: formatOptions))
        try #require(input!.appending(suffix: "+", formattingResultWith: formatOptions) == nil) // invalid syntax
        try #require(input!.appending(suffix: "/", formattingResultWith: formatOptions) == nil) // still invalid syntax
        input = try #require(input!.appending(suffix: " ", formattingResultWith: formatOptions))
        input = try #require(input!.appending(suffix: "1", formattingResultWith: formatOptions))
        
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
        input = try #require(input!.appending(suffix: "2", formattingResultWith: formatOptions, allowingResultReplacement: true))
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "2")
        } else {
            Issue.record("Expected draft case")
        }
        
        // can append "+" to result
        input = .result(.real(1.0, .length))
        input = try #require(input!.appending(suffix: "+", formattingResultWith: formatOptions))
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
        input = try #require(input!.appending(suffix: "/4", formattingResultWith: formatOptions, trimmingSuffix: .whitespaceAndFractionSlash))
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1/4")
        } else {
            Issue.record("Expected draft case")
        }
        
        input = .draft(ValidExpressionPrefix("1/")!, nil)
        
        // sanity-check that this case doesn't work without trimmingSuffix
        try #require(input!.appending(suffix: "/4", formattingResultWith: formatOptions) == nil)
        
        // works with trimmingSuffix
        input = try #require(input!.appending(suffix: "/4", formattingResultWith: formatOptions, trimmingSuffix: .whitespaceAndFractionSlash))
        if case .draft(let prefix, _) = input {
            #expect(prefix.value == "1/4")
        } else {
            Issue.record("Expected draft case")
        }
    }
}
