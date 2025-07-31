import Testing
@testable import Wood_Calc

// Serialized: Citron is not thread-safe.
@Suite(.serialized)
struct InputTests {
    let input: Input
    
    init() {
        input = Input()
    }
    
    @Test func empty() {
        #expect(input.stringified == "")
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
        input.reset(.result(.real(1.0)))
        #expect(input.append("2") == false) // would not create a legal (prefix of an) expression
        #expect(input.append("2", canReplaceResult: true) == true) // okay to replace with a legal (prefix of an) expression
        #expect(input.stringified == "2")
        
        input.reset(.result(.real(1.0)))
        #expect(input.append("+") == true)
        #expect(input.stringified == "1\"+")
        
        input.reset(.result(.real(1.0)))
        #expect(input.append(" ", canReplaceResult: true) == false) // no whitespace-only strings if trying to overwrite a result
        #expect(input.stringified == "1\"")
    }
    
    @Test func appendDeletingSuffix() {
        input.reset(.string("1 "))
        #expect(input.append("/4") == false) // sanity-check that this case doesn't work without deletingSuffix
        #expect(input.stringified == "1 ")
        #expect(input.append("/4", deletingSuffix: [" ", "/"]) == true)
        #expect(input.stringified == "1/4")
        
        input.reset(.string("1/"))
        #expect(input.append("/4") == false) // sanity-check that this case doesn't work without deletingSuffix
        #expect(input.stringified == "1/")
        #expect(input.append("/4", deletingSuffix: [" ", "/"]) == true)
        #expect(input.stringified == "1/4")
    }
    
    @Test func resetToValidStringAndFormatsVerbatim() {
        input.reset(.string("1  + 1 "))
        #expect(input.stringified == "1  + 1 ")
    }
    
    @Test func resetToRationalResultAndFormat() {
        input.reset(.result(.rational(Rational(1, 2))))
        #expect(input.stringified == "1/2\"")
        #expect(input.error == nil)
    }
    
    @Test func resetToRealResultAndFormatWithError() {
        input.reset(.result(.real(0.501)))
        #expect(input.stringified == "1/2\"")
        let (precision, error) = input.error!
        #expect(precision == Constants.AppStorage.precisionDefault)
        #expect(error.isApproximatelyEqual(to: -0.001))
    }
    
    @Test func settingToInvalidStringDoesNothing() {
        input.reset(.string("1+1"))
        #expect(input.stringified == "1+1")
        input.reset(.string("+++"))
        #expect(input.stringified == "1+1")
    }
    
    @Test<[(Input.RawValue, Bool)]>(arguments: [
        (.result(.real(1.0)), false),
        (.result(.rational(Rational(1, 2))), false),
        (.string(""), false),
        (.string("1+1"), true),
    ]) func willBackspaceSingleCharacter(value: Input.RawValue, expected: Bool) {
        input.reset(value)
        #expect(input.willBackspaceSingleCharacter == expected)
    }
    
    @Test<[(Input.RawValue, String)]>(arguments: [
        (.result(.real(1.0)), ""),
        (.result(.rational(Rational(1, 2))), ""),
        (.string(""), ""),
        (.string("1+1"), "1+"),
    ]) func backspace(value: Input.RawValue, expected: String) {
        input.reset(value)
        input.backspace()
        #expect(input.stringified == expected)
    }
}
