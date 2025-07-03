import Testing
@testable import WoodworkingCalculator

struct FractionTests {    
    @Test func testExactEquality() {
        #expect(Fraction(1, 2) == Fraction(1, 2))
    }
    
    @Test func testReducibleEquality() {
        #expect(Fraction(1, 2) == Fraction(2, 4))
    }
    
    @Test func testNonEquality() {
        #expect(Fraction(1, 2) != Fraction(2, 3))
    }
    
    @Test(arguments: [
        (Fraction(2, 4), Fraction(1, 2)),
        (Fraction(17, 51), Fraction(1, 3)),
        (Fraction(2, 3), Fraction(2, 3)),
    ]) func reduced(_ input: (Fraction, Fraction)) {
        #expect(input.0.reduced == input.1)
    }
}
