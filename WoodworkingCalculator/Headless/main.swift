if CommandLine.argc != 2 {
    print("Pass the expression to be parsed as a quoted argument.")
} else {
    let inputString = CommandLine.arguments[1]
    do {
        try lexer.tokenize(inputString) { (t, c) in
            try parser.consume(token: t, code: c)
        }
        let tree = try parser.endParsing()
        print("\(tree) -> \(formatFraction(tree.evaluate()))")
    } catch (let error) {
        print("Error during parsing: \(error)")
    }
}
