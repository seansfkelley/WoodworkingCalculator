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
        #expect(input.stringified == "")
    }

    @Test func stringified() {
        input.reset(.string("1+2", nil))
        #expect(input.stringified == "1+2")
        
        input.reset(.string("(1+2", nil))
        #expect(input.stringified == "(1+2")

        input.reset(.result(.rational(rational(3, 4), .unitless)))
        #expect(input.stringified == "3/4\"")
    }

    @Test func append() {
        #expect(input.append(" ") == false) // no whitespace-only strings
        #expect(input.append("1") == true)
        #expect(input.append(" ") == true)
        #expect(input.append(" ") == false) // duplicative whitespace is ignored
        #expect(input.append("+") == true)
        #expect(input.append("+") == false) // not legal
        #expect(input.append("/") == false) // still not legal
        #expect(input.append(" ") == true)
        #expect(input.append("1") == true)
        #expect(input.stringified == "1 + 1")
    }

    @Test func appendingToResult() {
        input.reset(.result(.real(1.0, .unitless)))
        #expect(input.append("2") == false) // would not create a legal (prefix of an) expression
        #expect(input.append("2", canReplaceResult: true) == true) // okay to replace with a legal (prefix of an) expression
        #expect(input.stringified == "2")

        input.reset(.result(.real(1.0, .unitless)))
        #expect(input.append("+") == true)
        #expect(input.stringified == "1\"+")

        input.reset(.result(.real(1.0, .unitless)))
        #expect(input.append(" ", canReplaceResult: true) == false) // no whitespace-only strings if trying to overwrite a result
        #expect(input.stringified == "1\"")
    }

    @Test func appendDeletingSuffix() {
        input.reset(.string("1 ", nil))
        #expect(input.append("/4") == false) // sanity-check that this case doesn't work without deletingSuffix
        #expect(input.stringified == "1 ")
        #expect(input.append("/4", deletingSuffix: [" ", "/"]) == true)
        #expect(input.stringified == "1/4")

        input.reset(.string("1/", nil))
        #expect(input.append("/4") == false) // sanity-check that this case doesn't work without deletingSuffix
        #expect(input.stringified == "1/")
        #expect(input.append("/4", deletingSuffix: [" ", "/"]) == true)
        #expect(input.stringified == "1/4")
    }

    @Test func resetToValidStringAndFormatsVerbatim() {
        input.reset(.string("1  + 1 ", nil))
        #expect(input.stringified == "1  + 1 ")
    }

    @Test func resetToRationalResultAndFormat() {
        input.reset(.result(.rational(rational(1, 2), .unitless)))
        #expect(input.stringified == "1/2\"")
        #expect(input.error == nil)
    }

    @Test func resetToRealResultAndFormatWithAccuracy() {
        input.reset(.result(.real(0.501, .unitless)))
        #expect(input.stringified == "1/2\"")
        let (precision, accuracy, dimension) = input.inaccuracy!
        #expect(precision == Constants.AppStorage.precisionDefault)
        #expect(accuracy.isApproximatelyEqual(to: -0.001))
    }

    @Test func resetToErroredResult() {
        input.reset(.string("1/0", .divisionByZero))
        #expect(input.stringified == "1/0")
        #expect(input.error! as? EvaluationError == .divisionByZero)
    }

    @Test func settingToInvalidStringDoesNothing() {
        input.reset(.string("1+1", nil))
        #expect(input.stringified == "1+1")
        input.reset(.string("+++", nil))
        #expect(input.stringified == "1+1")
    }

    @Test<[(InputValue.RawValue, InputValue.BackspaceResult)]>(arguments: [
        (.result(.real(1.0, .unitless)), .clear),
        (.result(.rational(rational(1, 2), .unitless)), .clear),
        (.string("", nil), .string("")),
        (.string("1+1", nil), .string("1+")),
        (.string("1 ", nil), .string("1")),
        (.string("1/0", .divisionByZero), .string("1/")),
        (.string("1m", nil), .string("1")),
        (.string("1cm", nil), .string("1")),
        (.string("1mm", nil), .string("1")),
    ]) func backspaced(value: InputValue.RawValue, expected: InputValue.BackspaceResult) {
        input.reset(value)
        #expect(input.backspaced == expected)
    }
}
