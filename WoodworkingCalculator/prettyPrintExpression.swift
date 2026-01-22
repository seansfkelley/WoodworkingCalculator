func prettyPrintExpression(_ string: String) -> String {
    string
        .replacing(/(in|ft|mm|cm|m)(\[([0-9]+)\])?/, with: { match in
            let exponent = if let raw = match.3 {
                Int(raw)!
            } else {
                1
            }
            let unit = if match.1 == "in" && exponent == 1 {
                "\""
            } else if match.1 == "ft" && exponent == 1 {
                "'"
            } else {
                String(match.1)
            }
            return "\(unit)\(exponent == 1 ? "" : exponent.superscript)"
        })
        .replacing(/([0-9]) ([0-9]|$)/, with: { match in
            "\(match.1)\u{2002}\(match.2)"
        })
        .replacing(/([0-9]+)\/([0-9]*)/, with: { match in
            "\(Int(match.1)!.superscript)\u{2044}\(Int(match.2).map(\.subscript) ?? " ")"
        })
}
