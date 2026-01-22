import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct InputValueTests {
    let options = InputValue.FormattingOptions(unit: .inches, precision: .init(denominator: 16))

    let input: InputValue

    init() {
        input = InputValue()
    }

    @Test func empty() {
        #expect(input.formatted(with: options) == ("", nil))
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
        #expect(input.formatted(with: options) == ("1 + 1", nil))
    }

    @Test func appendingToResult() throws {
        input.setValue(to: .result(.real(1.0, .length)))
        try #require(input.append("2") == false) // would not create a legal (prefix of an) expression
        #expect(input.append("2", canReplaceResult: true) == true) // okay to replace with a legal (prefix of an) expression
        #expect(input.formatted(with: options) == ("2", nil))

        input.setValue(to: .result(.real(1.0, .length)))
        try #require(input.append("+") == true)
        #expect(input.formatted(with: options) == ("1in+", nil))

        input.setValue(to: .result(.real(1.0, .length)))
        try #require(input.append(" ", canReplaceResult: true) == false) // no whitespace-only strings if trying to overwrite a result
        #expect(input.formatted(with: options) == ("1in", nil))
    }

    @Test func appendDeletingSuffix() throws {
        input.setValue(to: .draft(.init("1 ")!, nil))
        try #require(input.append("/4") == false) // sanity-check that this case doesn't work without trimmingSuffix
        #expect(input.formatted(with: options) == ("1 ", nil))
        try #require(input.append("/4", trimmingSuffix: .whitespaceAndFractionSlash) == true)
        #expect(input.formatted(with: options) == ("1/4", nil))

        input.setValue(to: .draft(.init("1/")!, nil))
        try #require(input.append("/4") == false) // sanity-check that this case doesn't work without trimmingSuffix
        #expect(input.formatted(with: options) == ("1/", nil))
        try #require(input.append("/4", trimmingSuffix: .whitespaceAndFractionSlash) == true)
        #expect(input.formatted(with: options) == ("1/4", nil))
    }

    @Test func resetToValidStringAndFormatsVerbatim() {
        input.setValue(to: .draft(.init("1  + 1 ")!, nil))
        #expect(input.formatted(with: options) == ("1  + 1 ", nil))
    }

    @Test func resetToRationalResultAndFormat() {
        input.setValue(to: .result(.rational(rational(1, 2), .length)))
        #expect(input.formatted(with: options) == ("1/2in", nil))
    }

    @Test func resetToRealResultAndFormatWithAccuracy() throws {
        input.setValue(to: .result(.real(0.501, .length)))
        #expect(input.formatted.0 == "1/2in")
        let roundingError = input.formatted.1
        try #require(roundingError != nil)
        #expect(roundingError!.error.isApproximatelyEqual(to: -0.001))
        #expect(roundingError!.oneDimensionalPrecision == .init(denominator: 16))
        #expect(roundingError!.dimension == .length)
    }

    @Test func resetToErroredResult() {
        input.setValue(to: .draft(.init("1/0")!, .divisionByZero))
        #expect(input.formatted(with: options) == ("1/0", nil))
        #expect(input.error == .divisionByZero)
    }

    @Test func settingToNilDoesNothing() {
        input.setValue(to: .draft(.init("1+1")!, nil))
        #expect(input.formatted(with: options) == ("1+1", nil))
        input.setValue(to: nil)
        #expect(input.formatted(with: options) == ("1+1", nil))
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

//    @Test<[(InputValue.RawValue, (Int, Double, Dimension)?)]>(arguments: [
//        (.draft(.init("1+1")!, nil), nil),
//        (.draft(.init("1/0")!, .divisionByZero), nil),
//
//        // exact
//        (.result(.rational(rational(1, 2), .length)), nil),
//        (.result(.real(0.5, .length)), nil),
//
//        // length
//        (.result(.real(0.501, .length)), (Constants.AppStorage.precisionDefault, -0.001, .length)),
//        (.result(.real(1.0 / 3.0, .length)), (Constants.AppStorage.precisionDefault, 1.0 / 3.0 - Double(rational(1, 3)), .length)),
//
//        // area
//        (.result(.real(0.501, .area)), (Constants.AppStorage.precisionDefault, -0.001, .area)),
//
//        // volume
//        (.result(.real(0.501, .volume)), (Constants.AppStorage.precisionDefault, -0.001, .volume)),
//    ]) func inaccuracy(value: InputValue.RawValue, expected: (Int, Double, Dimension)?) {
//        input.setValue(to: value)
//        if let expected {
//            let (precision, accuracy, dimension) = input.inaccuracy!
//            #expect(precision == expected.0)
//            #expect(accuracy.isApproximatelyEqual(to: expected.1))
//            #expect(dimension == expected.2)
//        } else {
//            #expect(input.inaccuracy == nil)
//        }
//    }
}
