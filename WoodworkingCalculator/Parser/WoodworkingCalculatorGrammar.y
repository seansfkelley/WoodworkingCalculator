%class_name WoodworkingCalculatorGrammar

%token_type Token

%nonterminal_type equation Evaluatable
equation ::= expression(e). {
    return e
}

%nonterminal_type expression Evaluatable
expression ::= expression(left) Add multiplicative(right). {
    return .add(left, right)
}
expression ::= expression(left) Subtract multiplicative(right). {
    return .subtract(left, right)
}
expression ::= multiplicative(x). {
    return x
}

%nonterminal_type multiplicative Evaluatable
multiplicative ::= multiplicative(left) Multiply atom(right). {
    return .multiply(left, right)
}
multiplicative ::= multiplicative(left) Divide atom(right). {
    return .divide(left, right)
}
multiplicative ::= atom(x). {
    return x
}

%nonterminal_type atom Evaluatable
atom ::= quantity(x). {
    return x
}
atom ::= LeftParen expression(x) RightParen. {
    return x
}

%nonterminal_type quantity Evaluatable
quantity ::= integer(f) Feet integer(i_int) fraction(i_frac) Inches. {
    return .rational(Fraction((f * 12 + i_int) * i_frac.den + i_frac.num, i_frac.den))
}
quantity ::= integer(f) Feet integer(i_int) fraction(i_frac). {
    return .rational(Fraction((f * 12 + i_int) * i_frac.den + i_frac.num, i_frac.den))
}
quantity ::= integer(f) Feet integer(i_int) Inches. {
    return .rational(Fraction(f * 12 + i_int, 1))
}
quantity ::= integer(f) Feet integer(i_int). {
    return .rational(Fraction(f * 12 + i_int, 1))
}
quantity ::= integer(f) Feet fraction(i_frac) Inches. {
    return .rational(Fraction(f * 12 * i_frac.den + i_frac.num, i_frac.den))
}
quantity ::= integer(f) Feet fraction(i_frac). {
    return .rational(Fraction(f * 12 * i_frac.den + i_frac.num, i_frac.den))
}
quantity ::= integer(f) Feet real(i) Inches. {
    return .real(Double(f * 12) + i)
}
quantity ::= integer(f) Feet real(i). {
    return .real(Double(f * 12) + i)
}
quantity ::= integer(f) Feet. {
    return .rational(Fraction(f * 12, 1))
}
quantity ::= fraction(f) Feet. {
    return .rational(Fraction(f.num * 12, f.den))
}
quantity ::= real(f) Feet. {
    return .real(f * 12)
}
quantity ::= integer(i_int) fraction(i_frac) Inches. {
    return .rational(Fraction(i_int * i_frac.den + i_frac.num, i_frac.den))
}
quantity ::= integer(i_int) fraction(i_frac). {
    return .rational(Fraction(i_int * i_frac.den + i_frac.num, i_frac.den))
}
quantity ::= integer(i_int) Inches. {
    return .rational(Fraction(i_int, 1))
}
quantity ::= integer(i_int). {
    return .rational(Fraction(i_int, 1))
}
quantity ::= fraction(i_frac) Inches. {
    return .rational(Fraction(i_frac.num, i_frac.den))
}
quantity ::= fraction(i_frac). {
    return .rational(Fraction(i_frac.num, i_frac.den))
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

%nonterminal_type fraction Fraction
fraction ::= Fraction(x). {
    if case .fraction(let fraction) = x {
        return fraction
    } else {
        preconditionFailure("lexer did not return Token.fraction for the Fraction token")
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
