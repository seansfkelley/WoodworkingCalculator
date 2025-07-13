import Testing
import Numerics

@testable import WoodworkingCalculator

struct RationalTests {
    @Test("==", arguments: [
        (Rational(1, 2), Rational(1, 2)),
        (Rational(1, 2), Rational(3, 6)),
    ]) func equality(left: Rational, right: Rational) {
        #expect(left == right)
    }
    
    @Test("!=", arguments: [
        (Rational(1, 2), Rational(1, 3)),
    ]) func nonEquality(left: Rational, right: Rational) {
        #expect(left != right)
    }
    
    @Test("reduced", arguments: [
        (Rational(2, 4), Rational(1, 2)),
        (Rational(17, 51), Rational(1, 3)),
        (Rational(2, 3), Rational(2, 3)),
    ]) func reduced(input: Rational, expected: Rational) {
        let actual = input.reduced
        #expect(actual.num == expected.num)
        #expect(actual.den == expected.den)
    }
    
    @Test("roundedToPrecision", arguments: [
        (Rational(3, 32), 8, Rational(1, 8), 1 / 32),
        (Rational(1, 2), 4, Rational(1, 2), nil),
        (Rational(3, 4), 6, Rational(2, 3), -1 / 12),
    ]) func rounding(input: Rational, precision: Int, expected: Rational, expectedRemainder: Double?) {
        let actual = input.roundedToPrecision(precision)
        #expect(actual.0 == expected)
        if case .some(let actualRemainder) = actual.1, case .some(let expectedRemainder) = expectedRemainder {
            #expect(actualRemainder.isApproximatelyEqual(to: expectedRemainder))
        } else {
            #expect(actual.1 == expectedRemainder)
        }
    }
    
    @Test("arithmetic", arguments: [
        (Rational(1, 2) + Rational(1, 4), Rational(3, 4)),
        (Rational(1, 2) - Rational(1, 4), Rational(1, 4)),
        (Rational(1, 2) * Rational(3, 4), Rational(3, 8)),
        (Rational(1, 2) / Rational(1, 4), Rational(2, 1)),
    ]) func arithmetic(left: Rational, right: Rational) {
        #expect(left == right)
    }
}

let cases: [(input: Double, precision: Int, expected: Rational, expectedRemainder: Double?)] = [
    (31 / 32, 4, Rational(1, 1), 1 / 32),
    (33 / 32, 4, Rational(1, 1), -1 / 32),
    // Hmm, might want to turn the precision up here? This seems a bit weird that there's 0 error, though it _is_ less than a thou.
    (1 / 65, 64, Rational(1, 64), nil),
]

struct DoubleTests {
    @Test("init", arguments: [
        (Rational(1, 2), 1 / 2),
    ]) func init_(input: Rational, expected: Double) {
        #expect(Double(input).isApproximatelyEqual(to: expected))
    }
    
    @Test("toNearestRational", arguments: cases)
    func toNearestRational(input: Double, precision: Int, expected: Rational, expectedRemainder: Double?) {
        let actual = input.toNearestRational(withPrecision: precision)
        #expect(actual.0 == expected)
        if case .some(let actualRemainder) = actual.1, case .some(let expectedRemainder) = expectedRemainder {
            #expect(actualRemainder.isApproximatelyEqual(to: expectedRemainder))
        } else {
            #expect(actual.1 == expectedRemainder)
        }
    }
}
