import Testing
@testable import Wood_Calc

private func rational(_ num: Int, _ den: Int) -> Rational {
    try! UncheckedRational(num, den).checked.get()
}

struct QuantityTests {
    private let eighths = RationalPrecision(denominator: 8)

    @Test func rationalResultFormatted() throws {
        let quantity = Quantity.rational(rational(1, 2), .length)
        let (formatted, error) = quantity.formatted(with: .init(.inches, eighths, 3, 9))
        #expect(formatted == "1/2in")
        #expect(error == nil)
    }

    @Test func lengthFormattedWithRoundingError() throws {
        let quantity = Quantity.real(0.501, .length)
        let (formatted, err) = quantity.formatted(with: .init(.inches, eighths, 3, 9))
        #expect(formatted == "1/2in")
        let roundingError = try #require(err)
        #expect(roundingError.error.isApproximatelyEqual(to: -0.001))
        #expect(roundingError.oneDimensionalPrecision == eighths)
        #expect(roundingError.dimension == .length)
    }

    @Test func areaFormattedAsDecimal() throws {
        let quantity = Quantity.real(144.0, .area)
        let (formatted, roundingError) = quantity.formatted(with: .init(.feet, eighths, 3, 9))
        #expect(formatted == "1ft[2]")
        #expect(roundingError == nil)
    }

    @Test func unitlessFormattedIgnoresUnitAndRoundingError() throws {
        let quantity = Quantity.real(3.14159, .unitless)
        let (formatted, roundingError) = quantity.formatted(with: .init(.inches, eighths, 1, 3))
        #expect(formatted == "3.142")
        #expect(roundingError == nil)
    }

    @Test func dimensionalPrecisionAdjustment() throws {
        let quantity = Quantity.real(0.501, .area)
        let (_, err) = quantity.formatted(with: .init(.inches, eighths, 3, 9))

        let roundingError = try #require(err)
        #expect(roundingError.dimensionallyAdjustedPrecision.denominator == 64)
        #expect(roundingError.oneDimensionalPrecision == eighths)
        #expect(roundingError.dimension == .area)
    }

    @Test func metersReturnsNilForUnitless() {
        let quantity = Quantity.real(42.0, .unitless)
        #expect(quantity.meters == nil)
    }

    @Test func metersConvertsLengthCorrectly() throws {
        let quantity = Quantity.real(1.0, .length)
        let meters = try #require(quantity.meters)
        #expect(meters.isApproximatelyEqual(to: 0.0254))
    }

    @Test func metersConvertsAreaCorrectly() throws {
        let quantity = Quantity.real(1.0, .area)
        let meters = try #require(quantity.meters)
        #expect(meters.isApproximatelyEqual(to: 0.0254 * 0.0254))
    }

    @Test func toRealFromRational() {
        let quantity = Quantity.rational(rational(1, 2), .length)
        #expect(quantity.toReal() == 0.5)
    }

    @Test func toRealFromReal() {
        let quantity = Quantity.real(3.14159, .volume)
        #expect(quantity.toReal() == 3.14159)
    }

    @Test func toRationalFromRational() {
        let quantity = Quantity.rational(rational(3, 4), .length)
        let (result, error) = quantity.toRational(precision: eighths)
        #expect(result == rational(12, 16))
        #expect(error == 0.0)
    }

    @Test func toRationalFromReal() {
        let quantity = Quantity.real(0.501, .area)
        let (result, error) = quantity.toRational(precision: eighths)
        #expect(result == rational(1, 2))
        #expect(error.isApproximatelyEqual(to: -0.001))
    }

    @Test("withDimension", arguments: [
        (Quantity.rational(rational(3, 4), .length), Dimension.area, Quantity.rational(rational(3, 4), .area)),
        (Quantity.real(42.5, .volume), Dimension.unitless, Quantity.real(42.5, .unitless)),
    ]) func withDimension(original: Quantity, newDimension: Dimension, expected: Quantity) {
        #expect(original.withDimension(newDimension) == expected)
    }
}

