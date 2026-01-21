import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct InputValueTests {
    let input: InputValue

    init() {
        input = InputValue()
    }

    @Test func empty() {
        #expect(input.draft.value == "")
    }

    @Test func append() throws {
        try #require(input.append(" ") == false) // no whitespace-only strings
        try #require(input.append("1") == true)
        try #require(input.append(" ") == true)
        try #require(input.append(" ") == false) // duplicative whitespace is ignored
        try #require(input.append("+") == true)
        try #require(input.append("+") == false) // not legal
        try #require(input.append("/") == false) // still not legal
        try #require(input.append(" ") == true)
        try #require(input.append("1") == true)
        #expect(input.draft.value == "1 + 1")
    }

    @Test func appendingToResult() throws {
        input.setValue(to: .result(.real(1.0, .length)))
        try #require(input.append("2") == false) // would not create a legal (prefix of an) expression
        #expect(input.append("2", canReplaceResult: true) == true) // okay to replace with a legal (prefix of an) expression
        #expect(input.draft.value == "2")

        input.setValue(to: .result(.real(1.0, .length)))
        try #require(input.append("+") == true)
        #expect(input.draft.value == "1\"+")

        input.setValue(to: .result(.real(1.0, .length)))
        try #require(input.append(" ", canReplaceResult: true) == false) // no whitespace-only strings if trying to overwrite a result
        #expect(input.draft.value == "1\"")
    }

    @Test func appendDeletingSuffix() throws {
        input.setValue(to: .draft(.init("1 ")!, nil))
        try #require(input.append("/4") == false) // sanity-check that this case doesn't work without trimmingSuffix
        #expect(input.draft.value == "1 ")
        try #require(input.append("/4", trimmingSuffix: .whitespaceAndFractionSlash) == true)
        #expect(input.draft.value == "1/4")

        input.setValue(to: .draft(.init("1/")!, nil))
        try #require(input.append("/4") == false) // sanity-check that this case doesn't work without trimmingSuffix
        #expect(input.draft.value == "1/")
        try #require(input.append("/4", trimmingSuffix: .whitespaceAndFractionSlash) == true)
        #expect(input.draft.value == "1/4")
    }

    @Test func resetToValidStringAndFormatsVerbatim() {
        input.setValue(to: .draft(.init("1  + 1 ")!, nil))
        #expect(input.draft.value == "1  + 1 ")
    }

    @Test func resetToRationalResultAndFormat() {
        input.setValue(to: .result(.rational(rational(1, 2), .length)))
        #expect(input.draft.value == "1/2in1")
        #expect(input.error == nil)
    }

    @Test func resetToRealResultAndFormatWithAccuracy() {
        input.setValue(to: .result(.real(0.501, .length)))
        #expect(input.draft.value == "1/2\"")
        let (precision, accuracy, dimension) = input.inaccuracy!
        #expect(precision == Constants.AppStorage.precisionDefault)
        #expect(accuracy.isApproximatelyEqual(to: -0.001))
    }

    @Test func resetToErroredResult() {
        input.setValue(to: .draft(.init("1/0")!, .divisionByZero))
        #expect(input.draft.value == "1/0")
        #expect(input.error! as? EvaluationError == .divisionByZero)
    }

    @Test func settingToNilDoesNothing() {
        input.setValue(to: .draft(.init("1+1")!, nil))
        #expect(input.draft.value == "1+1")
        input.setValue(to: nil)
        #expect(input.draft.value == "1+1")
    }

    @Test<[(InputValue.RawValue, InputValue.BackspaceResult)]>(arguments: [
        (.result(.real(1.0, .length)), .clear),
        (.result(.rational(rational(1, 2), .length)), .clear),
        (.draft(.init("")!, nil), .draft(.init("")!)),
        (.draft(.init("1+1")!, nil), .draft(.init("1+")!)),
        (.draft(.init("1 ")!, nil), .draft(.init("1")!)),
        (.draft(.init("1/0")!, .divisionByZero), .draft(.init("1/")!)),
        (.draft(.init("1m")!, nil), .draft(.init("1")!)),
        (.draft(.init("1cm")!, nil), .draft(.init("1")!)),
        (.draft(.init("1mm")!, nil), .draft(.init("1")!)),
    ]) func backspaced(value: InputValue.RawValue, expected: InputValue.BackspaceResult) {
        input.setValue(to: value)
        #expect(input.backspaced == expected)
    }
}
