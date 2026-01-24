// To preserve migration safety, this should not store anything beyond primitives or types defined here.
struct StoredCalculation: Codable {
    enum Result: Codable {
        case real(Double, UInt)
        case rational(Int, Int, UInt)

        static func from(quantity: Quantity) -> Result {
            switch quantity {
            case .real(let value, let dimension): .real(value, dimension.value)
            case .rational(let rational, let dimension): .rational(rational.num, rational.den, dimension.value)
            }
        }

        var quantity: Quantity {
            switch self {
            case .real(let value, let dimension): .real(value, .init(dimension))
            case .rational(let num, let den, let dimension): .rational(UncheckedRational(num, den).unsafe, .init(dimension))
            }
        }
    }

    let input: String
    let result: Result
    let formattedResult: String
}
