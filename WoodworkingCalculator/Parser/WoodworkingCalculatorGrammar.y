%preface {
    func forceUnwrapDimension(_ token: WoodworkingCalculatorToken) -> Dimension {
        if case .dimension(let dim) = token {
            return dim
        } else {
            preconditionFailure("lexer did not return Dimension when expected")
        }
    }
}

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
atom ::= Subtract quantity(x). { .subtract(.rational(UncheckedRational(0, 1), .unitless), x) }
atom ::= LeftParen expression(x) RightParen. { x }
atom ::= Subtract LeftParen expression(x) RightParen. { .subtract(.rational(UncheckedRational(0, 1), .unitless), x) }

%nonterminal_type quantity EvaluatableCalculation
quantity ::= integer(q) meters(d). {
    // Decimal ratio is exact, by definition of the US customary system: 1" = 25.4mm.
    // https://en.wikipedia.org/wiki/United_States_customary_units#International_units
    .real(Double(q) / 0.0254, d)
}
quantity ::= real(q) meters(d). { .real(q / 0.0254, d) }
quantity ::= integer(q) centimeters(d). { .real(Double(q) / 2.54, d) }
quantity ::= real(q) centimeters(d). { .real(q / 2.54, d) }
quantity ::= integer(q) millimeters(d). { .real(Double(q) / 25.4, d) }
quantity ::= real(q) millimeters(d). { .real(q / 25.4, d) }
quantity ::= integer(f) Feet mixed_number(i) Inches. { .rational(UncheckedRational((f * 12) * i.den + i.num, i.den), .length) }
quantity ::= integer(f) dimensioned_feet(d) mixed_number(i). { .rational(UncheckedRational((f * 12) * i.den + i.num, i.den), d) }
quantity ::= integer(f) Feet integer(i) Inches. { .rational(UncheckedRational(f * 12 + i, 1), .length) }
quantity ::= integer(f) dimensioned_feet(d) integer(i). { .rational(UncheckedRational(f * 12 + i, 1), d) }
quantity ::= integer(f) Feet real(i) Inches. { .real(Double(f * 12) + i, .length) }
quantity ::= integer(f) dimensioned_feet(d) real(i). { .real(Double(f * 12) + i, d) }
quantity ::= integer(f) dimensioned_feet(d). { .rational(UncheckedRational(f * 12, 1), d) }
quantity ::= real(f) dimensioned_feet(d). { .real(f * 12, d) }
quantity ::= mixed_number(i) dimensioned_inches(d). { .rational(i, d) }
quantity ::= mixed_number(i). { .rational(i, .unitless) }
quantity ::= integer(i) dimensioned_inches(d). { .rational(UncheckedRational(i, 1), d) }
quantity ::= integer(i). { .rational(UncheckedRational(i, 1), .unitless) }
quantity ::= real(i) dimensioned_inches(d). { .real(i, d) }
quantity ::= real(i). { .real(i, .unitless) }

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

%nonterminal_type meters Dimension
meters ::= Meters(d). { forceUnwrapDimension(d) }

%nonterminal_type centimeters Dimension
centimeters ::= Centimeters(d). { forceUnwrapDimension(d) }

%nonterminal_type millimeters Dimension
millimeters ::= Millimeters(d). { forceUnwrapDimension(d) }

%nonterminal_type dimensioned_feet Dimension
dimensioned_feet ::= DimensionedFeet(d). { forceUnwrapDimension(d) }

%nonterminal_type dimensioned_inches Dimension
dimensioned_inches ::= DimensionedInches(d). { forceUnwrapDimension(d) }

%left_associative Add Subtract.
%left_associative Multiply Divide.
