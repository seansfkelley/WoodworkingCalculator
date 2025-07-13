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

%nonterminal_type atom EvaluatableCalculation
atom ::= quantity(x). {
    return x
}
atom ::= LeftParen expression(x) RightParen. {
    return x
}

%nonterminal_type quantity EvaluatableCalculation
quantity ::= integer(f) Feet mixed_number(i) Inches. {
    return .rational(Rational((f * 12) * i.den + i.num, i.den))
}
quantity ::= integer(f) Feet mixed_number(i). {
    return .rational(Rational((f * 12) * i.den + i.num, i.den))
}
quantity ::= integer(f) Feet integer(i) Inches. {
    return .rational(Rational(f * 12 + i, 1))
}
quantity ::= integer(f) Feet integer(i). {
    return .rational(Rational(f * 12 + i, 1))
}
quantity ::= integer(f) Feet real(i) Inches. {
    return .real(Double(f * 12) + i)
}
quantity ::= integer(f) Feet real(i). {
    return .real(Double(f * 12) + i)
}
quantity ::= integer(f) Feet. {
    return .rational(Rational(f * 12, 1))
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
    return .rational(Rational(i, 1))
}
quantity ::= integer(i). {
    return .rational(Rational(i, 1))
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
