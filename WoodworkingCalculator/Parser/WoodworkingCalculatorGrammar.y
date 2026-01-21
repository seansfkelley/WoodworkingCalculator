%class_name WoodworkingCalculatorGrammar

%token_type WoodworkingCalculatorToken

%nonterminal_type equation EvaluatableCalculation
equation ::= expression(e). { e }

%nonterminal_type expression EvaluatableCalculation
expression ::= expression(left) Add multiplicative(right). { .add(left, right) }
expression ::= expression(left) Subtract multiplicative(right). { .subtract(left, right) }
expression ::= multiplicative(x). { x }

%nonterminal_type multiplicative EvaluatableCalculation
multiplicative ::= multiplicative(left) Multiply atom(right). { .multiply(left, right) }
multiplicative ::= multiplicative(left) Divide atom(right). { .divide(left, right) }
multiplicative ::= atom(x). { x }

// We define unary negation non-recursively here so that you can't write ----4 (etc.). We also
// intentionally use a .rational as a minuend so that we (1) don't have to define a dedicated
// .negate operation and (2) so that if the subtrahend is a rational, we keep the whole expression
// rational instead of dropping down into floating-point.
%nonterminal_type atom EvaluatableCalculation
atom ::= quantity(x). { x }
atom ::= Subtract quantity(x). { .subtract(.rational(UncheckedRational(0, 1)), x) }
atom ::= LeftParen expression(x) RightParen. { x }
atom ::= Subtract LeftParen expression(x) RightParen. { .subtract(.rational(UncheckedRational(0, 1)), x) }

%nonterminal_type quantity EvaluatableCalculation
quantity ::= integer(q) Meters. {
    // Decimal ratio is exact, by definition of the US customary system: 1" = 25.4mm.
    // https://en.wikipedia.org/wiki/United_States_customary_units#International_units
    return .real(Double(q) / 0.0254)
}
quantity ::= real(q) Meters. { .real(q / 0.0254) }
quantity ::= integer(q) Centimeters. { .real(Double(q) / 2.54) }
quantity ::= real(q) Centimeters. { .real(q / 2.54) }
quantity ::= integer(q) Millimeters. { .real(Double(q) / 25.4) }
quantity ::= real(q) Millimeters. { .real(q / 25.4) }
quantity ::= integer(f) Feet mixed_number(i) Inches. { .rational(UncheckedRational((f * 12) * i.den + i.num, i.den)) }
quantity ::= integer(f) Feet mixed_number(i). { .rational(UncheckedRational((f * 12) * i.den + i.num, i.den)) }
quantity ::= integer(f) Feet integer(i) Inches. { .rational(UncheckedRational(f * 12 + i, 1)) }
quantity ::= integer(f) Feet integer(i). { .rational(UncheckedRational(f * 12 + i, 1)) }
quantity ::= integer(f) Feet real(i) Inches. { .real(Double(f * 12) + i) }
quantity ::= integer(f) Feet real(i). { .real(Double(f * 12) + i) }
quantity ::= integer(f) Feet. { .rational(UncheckedRational(f * 12, 1)) }
quantity ::= real(f) Feet. { .real(f * 12) }
quantity ::= mixed_number(i) Inches. { .rational(i) }
quantity ::= mixed_number(i). { .rational(i) }
quantity ::= integer(i) Inches. { .rational(UncheckedRational(i, 1)) }
quantity ::= integer(i). { .rational(UncheckedRational(i, 1)) }
quantity ::= real(i) Inches. { .real(i) }
quantity ::= real(i). { .real(i) }

%nonterminal_type integer Int
integer ::= Integer(x). {
    if case .integer(let int) = x {
        return int
    } else {
        preconditionFailure("lexer did not return Token.integer for the Integer token")
    }
}

%nonterminal_type mixed_number UncheckedRational
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
