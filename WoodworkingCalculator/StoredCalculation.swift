// To preserve migration safety, this should not store anything beyond primitives or types defined here.
struct StoredCalculation: Codable {
    // Unsure how to enforce this without blowing up the type complexity in this file considerably,
    // but, this this never be constructed directly -- only from a Quantity. This helps enforce the
    // runtime-only assertion that the rational's denominator is not zero.
    enum StoredQuantity: Codable {
        case real(Double, dimension: UInt)
        case rational(Int, Int, dimension: UInt)

        static func from(quantity: Quantity) -> StoredQuantity {
            switch quantity {
            case .real(let value, let dimension): .real(value, dimension: dimension.value)
            case .rational(let rational, let dimension): .rational(rational.num, rational.den, dimension: dimension.value)
            }
        }

        var deserialized: Quantity {
            switch self {
            case .real(let value, let dimension): .real(value, .init(dimension))
            case .rational(let num, let den, let dimension): .rational(UncheckedRational(num, den).unsafe, .init(dimension))
            }
        }
    }

    struct StoredResult: Codable {
        let quantity: StoredQuantity
        let noUnitsSpecified: Bool

        static func from(result: EvaluationResult) -> StoredResult {
            .init(
                quantity: .from(quantity: result.actualQuantity),
                noUnitsSpecified: result.noUnitsSpecified,
            )
        }

        var deserialized: EvaluationResult {
            EvaluationResult(actualQuantity: quantity.deserialized, noUnitsSpecified: noUnitsSpecified)
        }
    }

    let input: String
    let result: StoredResult
    let formattedResult: String
}
