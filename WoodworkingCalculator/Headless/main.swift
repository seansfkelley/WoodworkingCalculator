if CommandLine.argc != 2 {
    print("Pass the expression to be parsed as a quoted argument.")
} else {
    do {
        let tree = try parse(CommandLine.arguments[1])
        let result = tree.evaluate()
        let (rational, error) = switch result {
        case .rational(let r):
            r.roundedToPrecision(64)
        case .real(let r):
            r.toNearestRational(withPrecision: 64)
        }
        if error == nil {
            print("\(tree) -> \(formatAsUsCustomary(rational, .feet))")
        } else {
            print("\(tree) -> aprx. \(formatAsUsCustomary(rational, .feet)) (error: \(String(format: "%+.3f", error!))\")")
        }
    } catch (let error) {
        print("Error during parsing: \(error)")
    }
}
