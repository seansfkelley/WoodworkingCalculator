import Testing
import Numerics

@testable import Wood_Calc

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
        (Rational(-1, -2), Rational(1, 2)),
        (Rational(1, -2), Rational(-1, 2)),
    ]) func reduced(input: Rational, expected: Rational) {
        let actual = input.reduced
        #expect(actual.num == expected.num)
        #expect(actual.den == expected.den)
    }
    
    @Test("signum", arguments: [
        (Rational(1, 2), 1),
        (Rational(0, 1), 0),
        (Rational(-1, -2), 1),
        (Rational(-1, 2), -1),
        (Rational(1, -2), -1),
    ]) func signum(input: Rational, expected: Int) {
        #expect(input.signum() == expected)
    }
    
    @Test("description", arguments: [
        (Rational(2, 4), "2/4"),
    ]) func description(input: Rational, expected: String) {
        #expect(input.description == expected)
    }
    
    @Test("roundedToPrecision", arguments: [
        (Rational(3, 32), 8, Rational(1, 8), 1 / 32),
        (Rational(1, 2), 4, Rational(1, 2), nil),
        (Rational(3, 4), 6, Rational(2, 3), -1 / 12),
    ]) func roundedToPrecision(input: Rational, precision: Int, expected: Rational, expectedRemainder: Double?) {
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

struct DoubleTests {
    @Test("init", arguments: [
        (Rational(1, 2), 1 / 2),
    ]) func init_(input: Rational, expected: Double) {
        #expect(Double(input).isApproximatelyEqual(to: expected))
    }
    
    @Test<[(input: Double, precision: Int, expected: Rational, expectedRemainder: Double?)]>("toNearestRational", arguments: [
        (31.0 / 32, 4, Rational(1, 1), 1.0 / 32),
        (33.0 / 32, 4, Rational(1, 1), -1.0 / 32),
        // Hmm, might want to turn the precision up here? This seems a bit weird that there's 0 error, though it _is_ less than a thou.
        (1.0 / 65, 64, Rational(1, 64), nil),
    ]) func toNearestRational(input: Double, precision: Int, expected: Rational, expectedRemainder: Double?) {
        let actual = input.toNearestRational(withPrecision: precision)
        #expect(actual.0 == expected)
        if case .some(let actualRemainder) = actual.1, case .some(let expectedRemainder) = expectedRemainder {
            #expect(actualRemainder.isApproximatelyEqual(to: expectedRemainder))
        } else {
            #expect(actual.1 == expectedRemainder)
        }
    }
}
