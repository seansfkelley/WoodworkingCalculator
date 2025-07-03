if CommandLine.argc != 2 {
    print("Pass the expression to be parsed as a quoted argument.")
} else {
    do {
        let tree = try parse(CommandLine.arguments[1])
        let result = tree.evaluate()
        switch result {
        case .rational(let r):
            print("\(tree) -> \(r)")
        case .real(let r):
            let (fraction, error) = r.nearestFraction()
            if error == nil {
                print("\(tree) -> \(fraction)")
            } else {
                print("\(tree) -> aprx. \(fraction) (error: \(String(format: "%+.3f", error!))\")")
            }
        }
    } catch (let error) {
        print("Error during parsing: \(error)")
    }
}
