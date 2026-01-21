extension Int {
    var superscript: String {
        String(self).replacing(/[0-9\-]/, with: { [unicodeSuperscript[$0.output.first!]!] })
    }

    var `subscript`: String {
        String(self).replacing(/[0-9\-]/, with: { [unicodeSubscript[$0.output.first!]!] })
    }
}

private let unicodeSuperscript: [Character: Character] = [
    "0": "⁰",
    "1": "¹",
    "2": "²",
    "3": "³",
    "4": "⁴",
    "5": "⁵",
    "6": "⁶",
    "7": "⁷",
    "8": "⁸",
    "9": "⁹",
    "-": "⁻",
]

private let unicodeSubscript: [Character: Character] = [
    "0": "₀",
    "1": "₁",
    "2": "₂",
    "3": "₃",
    "4": "₄",
    "5": "₅",
    "6": "₆",
    "7": "₇",
    "8": "₈",
    "9": "₉",
    "-": "₋",
]
