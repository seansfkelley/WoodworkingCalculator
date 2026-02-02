import Testing
import Numerics

@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct RationalTests {
    @Test("==", arguments: [
        (rational(1, 2), rational(1, 2)),
        (rational(1, 2), rational(3, 6)),
        (rational(1, -2), rational(-1, 2)),
    ]) func equality(left: Rational, right: Rational) {
        #expect(left == right)
    }
    
    @Test("!=", arguments: [
        (rational(1, 2), rational(1, 3)),
    ]) func nonEquality(left: Rational, right: Rational) {
        #expect(left != right)
    }
    
    @Test("init reduces", arguments: [
        (rational(2, 4), rational(1, 2)),
        (rational(17, 51), rational(1, 3)),
        (rational(2, 3), rational(2, 3)),
        (rational(-1, -2), rational(1, 2)),
        (rational(1, -2), rational(-1, 2)),
    ]) func reduced(actual: Rational, expected: Rational) {
        #expect(actual.num == expected.num)
        #expect(actual.den == expected.den)
    }
    
    @Test("signum", arguments: [
        (rational(1, 2), 1),
        (rational(0, 1), 0),
        (rational(0, -1), 0),
        (rational(-1, -2), 1),
        (rational(-1, 2), -1),
        (rational(1, -2), -1),
    ]) func signum(input: Rational, expected: Int) {
        #expect(input.signum() == expected)
    }
    
    @Test("description", arguments: [
        (rational(1, 2), "1/2"),
        (rational(0, -1), "0/-1"),
        (rational(-2, 1), "-2/1"),
    ]) func description(input: Rational, expected: String) {
        #expect(input.description == expected)
    }

    @Test("formatted", arguments: [
        (rational(1, 2), "1/2"),
        (rational(3, 1), "3"),
        (rational(-1, -2), "1/2"),
        (rational(0, -2), "0"),
        (rational(1, -2), "-1/2"),
    ]) func formatted(input: Rational, expected: String) {
        #expect(input.formatted == expected)
    }

    @Test("roundedTo", arguments: [
        (rational(1, 2), 4, rational(1, 2), 0.0),
        (rational(3, 32), 8, rational(1, 8), 1.0 / 32),
        (rational(7, 64), 8, rational(1, 8), 1.0 / 64),
        (rational(9, 64), 8, rational(1, 8), -1.0 / 64),
        (rational(3, 4), 6, rational(2, 3), -1.0 / 12),
    ]) func roundedTo(input: Rational, denominator: Int, expected: Rational, expectedRemainder: Double) {
        let actual = input.roundedTo(precision: RationalPrecision(denominator: UInt(denominator)))
        #expect(actual.0 == expected)
        #expect(actual.1.isApproximatelyEqual(to: expectedRemainder))
    }
    
    @Test("arithmetic", arguments: [
        (rational(1, 2) + rational(1, 4), rational(3, 4)),
        (rational(1, 2) - rational(1, 4), rational(1, 4)),
        (rational(1, 2) * rational(3, 4), rational(3, 8)),
        (rational(1, 2) / rational(1, 4), rational(2, 1)),
    ]) func arithmetic(actual: Result<Rational, EvaluationError>, expected: Rational) {
        #expect(actual == .success(expected))
    }
}

struct UncheckedRationalTests {
    @Test("checked", arguments: [
        (UncheckedRational(1, 1), Result.success(rational(1, 1))),
        (UncheckedRational(1, 0), Result.failure(EvaluationError.divisionByZero)),
    ])
    func checked(input: UncheckedRational, expected: Result<Rational, EvaluationError>) {
        #expect(input.checked == expected)
    }
    
    @Test
    func unsafe() {
        #expect(UncheckedRational(1, 2).unsafe == rational(1, 2))
        // I don't know how to test for uncatchable runtime errors, so uh, just don't do it?
    }
    
    @Test("==", arguments: [
        (UncheckedRational(1, 2), UncheckedRational(1, 2)),
        (UncheckedRational(1, 2), UncheckedRational(3, 6)),
        (UncheckedRational(1, -2), UncheckedRational(-1, 2)),
    ]) func equality(left: UncheckedRational, right: UncheckedRational) {
        #expect(left == right)
    }
    
    @Test("!=", arguments: [
        (UncheckedRational(1, 2), UncheckedRational(1, 3)),
        (UncheckedRational(1, 2), UncheckedRational(2, 3)),
        (UncheckedRational(1, 0), UncheckedRational(2, 0)),
        (UncheckedRational(1, 0), UncheckedRational(1, 0)),
    ]) func nonEquality(left: UncheckedRational, right: UncheckedRational) {
        #expect(left != right)
    }
}

struct DoubleTests {
    @Test("init", arguments: [
        (rational(1, 2), 1 / 2),
    ]) func init_(input: Rational, expected: Double) {
        #expect(Double(input).isApproximatelyEqual(to: expected))
    }
    
    @Test("toNearestRational", arguments: [
        (31.0 / 32, 4, rational(1, 1), 1.0 / 32),
        (33.0 / 32, 4, rational(1, 1), -1.0 / 32),
        (1.0 / 65, 64, rational(1, 64), 1.0 / 64 - 1.0 / 65),
    ]) func toNearestRational(input: Double, denominator: Int, expected: Rational, expectedRemainder: Double) {
        let actual = input.toNearestRational(of: RationalPrecision(denominator: UInt(denominator)))
        #expect(actual.0 == expected)
        #expect(actual.1.isApproximatelyEqual(to: expectedRemainder))
    }
}
