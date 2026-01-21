enum Quantity: Equatable {
    case rational(Rational)
    case real(Double)
}

extension Double {
    init(_ result: Quantity) {
        switch (result) {
        case .rational(let f):
            self = Double(f)
        case .real(let r):
            self = r
        }
    }
}
