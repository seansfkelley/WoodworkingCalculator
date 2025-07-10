import Testing
import Numerics

@testable import WoodworkingCalculator

struct FractionTests {
    @Test("==", arguments: [
        (Fraction(1, 2), Fraction(1, 2)),
        (Fraction(1, 2), Fraction(3, 6)),
    ]) func equality(left: Fraction, right: Fraction) {
        #expect(left == right)
    }
    
    @Test("!=", arguments: [
        (Fraction(1, 2), Fraction(1, 3)),
    ]) func nonEquality(left: Fraction, right: Fraction) {
        #expect(left != right)
    }
    
    @Test("reduced", arguments: [
        (Fraction(2, 4), Fraction(1, 2)),
        (Fraction(17, 51), Fraction(1, 3)),
        (Fraction(2, 3), Fraction(2, 3)),
    ]) func reduced(input: Fraction, expected: Fraction) {
        let actual = input.reduced
        #expect(actual.num == expected.num)
        #expect(actual.den == expected.den)
    }
    
    @Test("roundedToPrecision", arguments: [
        (Fraction(3, 32), 8, Fraction(1, 8), 1 / 32),
        (Fraction(1, 2), 4, Fraction(1, 2), nil),
        (Fraction(3, 4), 6, Fraction(2, 3), -1 / 12),
    ]) func rounding(input: Fraction, precision: Int, expected: Fraction, expectedRemainder: Double?) {
        let actual = input.roundedToPrecision(precision)
        #expect(actual.0 == expected)
        if case .some(let actualRemainder) = actual.1, case .some(let expectedRemainder) = expectedRemainder {
            #expect(actualRemainder.isApproximatelyEqual(to: expectedRemainder))
        } else {
            #expect(actual.1 == expectedRemainder)
        }
    }
    
    @Test("arithmetic", arguments: [
        (Fraction(1, 2) + Fraction(1, 4), Fraction(3, 4)),
        (Fraction(1, 2) - Fraction(1, 4), Fraction(1, 4)),
        (Fraction(1, 2) * Fraction(3, 4), Fraction(3, 8)),
        (Fraction(1, 2) / Fraction(1, 4), Fraction(2, 1)),
    ]) func arithmetic(left: Fraction, right: Fraction) {
        #expect(left == right)
    }
}

let cases: [(input: Double, precision: Int, expected: Fraction, expectedRemainder: Double?)] = [
    (31 / 32, 4, Fraction(1, 1), 1 / 32),
    (33 / 32, 4, Fraction(1, 1), -1 / 32),
    // Hmm, might want to turn the precision up here? This seems a bit weird that there's 0 error, though it _is_ less than a thou.
    (1 / 65, 64, Fraction(1, 64), nil),
]

struct DoubleTests {
    @Test("init", arguments: [
        (Fraction(1, 2), 1 / 2),
    ]) func init_(input: Fraction, expected: Double) {
        #expect(Double(input).isApproximatelyEqual(to: expected))
    }
    
    @Test("toNearestFraction", arguments: cases) func toNearestFraction(input: Double, precision: Int, expected: Fraction, expectedRemainder: Double?) {
        let actual = input.toNearestFraction(withPrecision: precision)
        #expect(actual.0 == expected)
        if case .some(let actualRemainder) = actual.1, case .some(let expectedRemainder) = expectedRemainder {
            #expect(actualRemainder.isApproximatelyEqual(to: expectedRemainder))
        } else {
            #expect(actual.1 == expectedRemainder)
        }
    }
}
