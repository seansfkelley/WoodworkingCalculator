if CommandLine.argc != 2 {
    print("Pass the expression to be parsed as a quoted argument.")
} else {
    do {
        let tree = try parse(CommandLine.arguments[1])
        print("\(tree) -> \(formatFraction(tree.evaluate()))")
    } catch (let error) {
        print("Error during parsing: \(error)")
    }
}
