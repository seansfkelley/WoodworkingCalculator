enum Quantity: Equatable {
    case rational(Rational, Dimension)
    case real(Double, Dimension)
}

extension Double {
    init(_ result: Quantity) {
        switch (result) {
        case .rational(let f, _):
            self = Double(f)
        case .real(let r, _):
            self = r
        }
    }
}
