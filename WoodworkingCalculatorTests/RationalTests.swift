import Testing
import Numerics

@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct RationalTests {
    // TODO: tests for formatted
    // TODO: tests for unchecked.unsafe

    @Test("==", arguments: [
        (rational(1, 2), rational(1, 2)),
        (rational(1, 2), rational(3, 6)),
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
        (rational(-1, -2), 1),
        (rational(-1, 2), -1),
        (rational(1, -2), -1),
    ]) func signum(input: Rational, expected: Int) {
        #expect(input.signum() == expected)
    }
    
    @Test("description", arguments: [
        (rational(1, 2), "1/2"),
    ]) func description(input: Rational, expected: String) {
        #expect(input.description == expected)
    }
    
    @Test("roundedTo", arguments: [
        (rational(3, 32), 8, rational(1, 8), 1.0 / 32),
        (rational(7, 64), 8, rational(1, 8), 1.0 / 64),
        (rational(9, 64), 8, rational(1, 8), -1.0 / 64),
        (rational(1, 2), 4, rational(1, 2), 0.001),
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
    
    @Test("checked", arguments: [
        (UncheckedRational(1, 1), Result.success(rational(1, 1))),
        (UncheckedRational(1, 0), Result.failure(EvaluationError.divisionByZero)),
    ])
    func checked(input: UncheckedRational, expected: Result<Rational, EvaluationError>) {
        #expect(input.checked == expected)
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
        // Hmm, might want to turn the precision up here? This seems a bit weird that there's 0 error, though it _is_ less than a thou.
        (1.0 / 65, 64, rational(1, 64), 0.001),
    ]) func toNearestRational(input: Double, denominator: Int, expected: Rational, expectedRemainder: Double) {
        let actual = input.toNearestRational(of: RationalPrecision(denominator: UInt(denominator)))
        #expect(actual.0 == expected)
        #expect(actual.1.isApproximatelyEqual(to: expectedRemainder))
    }
}
