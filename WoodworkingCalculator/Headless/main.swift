if CommandLine.argc != 2 {
    print("Pass the expression to be parsed as a quoted argument.")
} else {
    do {
        let tree = try parse(CommandLine.arguments[1])
        let result = tree.evaluate()
        let (fraction, error) = switch result {
        case .rational(let r):
            r.roundedToPrecision(HIGHEST_PRECISION)
        case .real(let r):
            r.toNearestFraction(withPrecision: HIGHEST_PRECISION)
        }
        if error == nil {
            print("\(tree) -> \(formatAsUsCustomary(fraction, .feet))")
        } else {
            print("\(tree) -> aprx. \(formatAsUsCustomary(fraction, .feet)) (error: \(String(format: "%+.3f", error!))\")")
        }
    } catch (let error) {
        print("Error during parsing: \(error)")
    }
}
