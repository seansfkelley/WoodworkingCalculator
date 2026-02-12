import Foundation

// Exists because there are multi-character sequences that must be trimmed as an atomic unit.
// We want to make sure that callers don't try to chop single characters off the end because they
// might create something very invalid.
//
// As of this writing there are no trim rules that interact with such multi-character sequences, but
// the backspace logic which is related to this does, so I took the opportunity to move all the
// logic here instead.
enum TrimmableCharacterSet {
    case whitespaceAndFractionSlash
    case redundantLeadingZeroes

    func trim(_ s: String) -> String {
        switch self {
        case .whitespaceAndFractionSlash:
            let trimmable = Set<Character>([" ", "/"])
            var result = s
            while result.count > 0 && trimmable.contains(result.last!) {
                result.removeLast()
            }
            return result
        case .redundantLeadingZeroes:
            return if let match = try? /^(|.*[^.0-9])(0+)$/.wholeMatch(in: s) {
                String(match.output.1)
            } else {
                s
            }
        }
    }
}

// The only reason this is separated from InputValue is because we don't want to be forced to carry
// a potential error around for storing an input string in history. Minorly, we also don't want to
// conflate results with inputs, which InputValue is intended to gloss over.
struct ValidExpressionPrefix: Equatable, CustomStringConvertible {
    let value: String

    init() {
        value = ""
    }

    init?(_ string: String) {
        guard EvaluatableCalculation.isValidPrefix(string) else {
            return nil
        }
        value = string
    }

    init(_ quantity: Quantity, with options: Quantity.FormattingOptions) {
        value = quantity.formatted(with: options).0
    }

    // Better to use this than to non-null assert -- in the worst case, the user will get into a
    // weird state and either kill the program or hit clear-all rather than it just crashing
    // outright. Not great, but way less obnoxious.
    private init (unsafe: String) {
        value = unsafe
    }

    var description: String { value }

    var backspaced: ValidExpressionPrefix {
        // If modifying this, modify String.withPrettyNumbers/Dimension.formatted.
        // (I could not think of a way to couple them together at compile time.)
        if let match = value.firstMatch(of: /(in|ft|mm|cm|m)(\[[0-9]+\])?$/) {
            .init(unsafe: String(value[..<match.output.0.startIndex]))
        } else {
            .init(unsafe: value.count == 0 ? "" : String(value.prefix(value.count - 1)))
        }
    }

    func append(_ suffix: String, trimmingSuffix trimmableCharacters: TrimmableCharacterSet? = nil) -> ValidExpressionPrefix? {
        let string = trimmableCharacters?.trim(value) ?? value
        return .init((string + suffix).replacing(/\ +/, with: " "))
    }
}
