import Testing
@testable import Wood_Calc

struct PrettyPrintExpressionTests {
    @Test<[(String, String)]>("prettyPrintExpression", arguments: [
        ("42", "42"),
        ("3.142", "3.142"),
        ("0in", "0\""),
        ("1/2in", "¹⁄₂\""),
        ("-1/2in", "-¹⁄₂\""),
        ("12in", "12\""),
        ("1ft", "1'"),
        ("15 3/8in", "15\u{2002}³⁄₈\""),
        ("144in[2]", "144in²"),
        ("25.5in[2]", "25.5in²"),
        ("1728ft[3]", "1728ft³"),
        ("3/", "³⁄ "), // note the trailing space -- the fraction slash gets cut off without a "denominator"
        ("12 3/", "12\u{2002}³⁄ "), // note the trailing space again
        ("12 ", "12\u{2002}"), // this space might not end up as a mixed number but we widen it for visuals anyway
        ("4ft 5", "4' 5"),
        ("12in+3/4in", "12\"+³⁄₄\""),
        ("5ft 3in×2", "5' 3\"×2"),
        ("(1/2in+3/4in)×3", "(¹⁄₂\"+³⁄₄\")×3"),
        ("3 1/2in×4 3/8in", "3\u{2002}¹⁄₂\"×4\u{2002}³⁄₈\""),
    ]) func testPrettyPrintExpression(input: String, expected: String) throws {
        #expect(prettyPrintExpression(input) == expected)
    }
}
