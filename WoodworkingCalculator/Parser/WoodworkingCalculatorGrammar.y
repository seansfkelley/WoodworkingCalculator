%class_name WoodworkingCalculatorParser

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
// Decimal ratio is exact, by definition of the US customary system: 1" = 25.4mm.
// https://en.wikipedia.org/wiki/United_States_customary_units#International_units
quantity ::= integer(q) Meters dimension(d). { .real(Double(q) / 0.0254, d) }
quantity ::= integer(q) Meters.              { .real(Double(q) / 0.0254, .length) }
quantity ::= real(q) Meters dimension(d).    { .real(q / 0.0254, d) }
quantity ::= real(q) Meters.                 { .real(q / 0.0254, .length) }

quantity ::= integer(q) Centimeters dimension(d). { .real(Double(q) / 2.54, d) }
quantity ::= integer(q) Centimeters.              { .real(Double(q) / 2.54, .length) }
quantity ::= real(q) Centimeters dimension(d).    { .real(q / 2.54, d) }
quantity ::= real(q) Centimeters.                 { .real(q / 2.54, .length) }

quantity ::= integer(q) Millimeters dimension(d). { .real(Double(q) / 25.4, d) }
quantity ::= integer(q) Millimeters.              { .real(Double(q) / 25.4, .length) }
quantity ::= real(q) Millimeters dimension(d).    { .real(q / 25.4, d) }
quantity ::= real(q) Millimeters.                 { .real(q / 25.4, .length) }

quantity ::= integer(f) Feet mixed_number(i) Inches. { .rational(UncheckedRational((f * 12) * i.den + i.num, i.den), .length) }
quantity ::= integer(f) Feet integer(i) Inches.      { .rational(UncheckedRational(f * 12 + i, 1), .length) }
quantity ::= integer(f) Feet real(i) Inches.         { .real(Double(f * 12) + i, .length) }
quantity ::= integer(f) Feet mixed_number(i).        { .rational(UncheckedRational((f * 12) * i.den + i.num, i.den), .length) }
quantity ::= integer(f) Feet integer(i).             { .rational(UncheckedRational(f * 12 + i, 1), .length) }
quantity ::= integer(f) Feet real(i).                { .real(Double(f * 12) + i, .length) }

quantity ::= integer(f) Feet dimension(d). { .rational(UncheckedRational(f * 12, 1), d) }
quantity ::= integer(f) Feet.              { .rational(UncheckedRational(f * 12, 1), .length) }
quantity ::= real(f) Feet dimension(d).    { .real(f * 12, d) }
quantity ::= real(f) Feet.                 { .real(f * 12, .length) }

quantity ::= mixed_number(i) Inches dimension(d). { .rational(i, d) }
quantity ::= mixed_number(i) Inches.              { .rational(i, .length) }
quantity ::= mixed_number(i).                     { .rational(i, .unitless) }
quantity ::= integer(i) Inches dimension(d).      { .rational(UncheckedRational(i, 1), d) }
quantity ::= integer(i) Inches.                   { .rational(UncheckedRational(i, 1), .length) }
quantity ::= integer(i).                          { .rational(UncheckedRational(i, 1), .unitless) }
quantity ::= real(i) Inches dimension(d).         { .real(i, d) }
quantity ::= real(i) Inches.                      { .real(i, .length) }
quantity ::= real(i).                             { .real(i, .unitless) }

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

%nonterminal_type dimension Dimension
dimension ::= Dimension(x). {
    if case .dimension(let dimension) = x {
        return dimension
    } else {
        preconditionFailure("lexer did not return Token.dimension for the Dimension token")
    }
}

%left_associative Add Subtract.
%left_associative Multiply Divide.
