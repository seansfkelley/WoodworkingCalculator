%class_name WoodworkingCalculatorGrammar

%token_type Token

%nonterminal_type equation EvaluatableCalculation
equation ::= expression(e). {
    return e
}

%nonterminal_type expression EvaluatableCalculation
expression ::= expression(left) Add multiplicative(right). {
    return .add(left, right)
}
expression ::= expression(left) Subtract multiplicative(right). {
    return .subtract(left, right)
}
expression ::= multiplicative(x). {
    return x
}

%nonterminal_type multiplicative EvaluatableCalculation
multiplicative ::= multiplicative(left) Multiply atom(right). {
    return .multiply(left, right)
}
multiplicative ::= multiplicative(left) Divide atom(right). {
    return .divide(left, right)
}
multiplicative ::= atom(x). {
    return x
}

// We define unary negation non-recursively here so that you can't write ----4 (etc.). We also
// intentionally use a .rational as a minuend so that we (1) don't have to define a dedicated
// .negate operation and (2) so that if the subtrahend is a rational, we keep the whole expression
// rational instead of dropping down into floating-point.
%nonterminal_type atom EvaluatableCalculation
atom ::= quantity(x). {
    return x
}
atom ::= Subtract quantity(x). {
    return .subtract(.rational(UncheckedRational(0, 1)), x)
}
atom ::= LeftParen expression(x) RightParen. {
    return x
}
atom ::= Subtract LeftParen expression(x) RightParen. {
    return .subtract(.rational(UncheckedRational(0, 1)), x)
}

%nonterminal_type quantity EvaluatableCalculation
quantity ::= integer(q) Meters. {
    // Decimal ratio is exact, by definition of the US customary system: 1" = 25.4mm.
    // https://en.wikipedia.org/wiki/United_States_customary_units#International_units
    return .real(Double(q) / 0.0254)
}
quantity ::= real(q) Meters. {
    return .real(q / 0.0254) // Ratio is exact. See above.
}
quantity ::= integer(q) Centimeters. {
    return .real(Double(q) / 2.54) // Ratio is exact. See above.
}
quantity ::= real(q) Centimeters. {
    return .real(q / 2.54) // Ratio is exact. See above.
}
quantity ::= integer(q) Millimeters. {
    return .real(Double(q) / 25.4) // Ratio is exact. See above.
}
quantity ::= real(q) Millimeters. {
    return .real(q / 25.4) // Ratio is exact. See above.
}
quantity ::= integer(f) Feet mixed_number(i) Inches. {
    return .rational(UncheckedRational((f * 12) * i.den + i.num, i.den))
}
quantity ::= integer(f) Feet mixed_number(i). {
    return .rational(UncheckedRational((f * 12) * i.den + i.num, i.den))
}
quantity ::= integer(f) Feet integer(i) Inches. {
    return .rational(UncheckedRational(f * 12 + i, 1))
}
quantity ::= integer(f) Feet integer(i). {
    return .rational(UncheckedRational(f * 12 + i, 1))
}
quantity ::= integer(f) Feet real(i) Inches. {
    return .real(Double(f * 12) + i)
}
quantity ::= integer(f) Feet real(i). {
    return .real(Double(f * 12) + i)
}
quantity ::= integer(f) Feet. {
    return .rational(UncheckedRational(f * 12, 1))
}
quantity ::= real(f) Feet. {
    return .real(f * 12)
}
quantity ::= mixed_number(i) Inches. {
    return .rational(i)
}
quantity ::= mixed_number(i). {
    return .rational(i)
}
quantity ::= integer(i) Inches. {
    return .rational(UncheckedRational(i, 1))
}
quantity ::= integer(i). {
    return .rational(UncheckedRational(i, 1))
}
quantity ::= real(i) Inches. {
    return .real(i)
}
quantity ::= real(i). {
    return .real(i)
}

%nonterminal_type integer Int
integer ::= Integer(x). {
    if case .integer(let int) = x {
        return int
    } else {
        preconditionFailure("lexer did not return Token.integer for the Integer token")
    }
}

%nonterminal_type mixed_number Rational
mixed_number ::= MixedNumber(x). {
    if case .rational(let r) = x {
        return r
    } else {
        preconditionFailure("lexer did not return Token.rational for the MixedNumber token")
    }
}

%nonterminal_type real Double
real ::= Real(x). {
    if case .real(let real) = x {
        return real
    } else {
        preconditionFailure("lexer did not return Token.real for the Real token")
    }
}

%left_associative Add Subtract.
%left_associative Multiply Divide.
