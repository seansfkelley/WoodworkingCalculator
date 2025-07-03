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
    return .quantity((f * 12 + i_int) * i_frac.1 + i_frac.0, i_frac.1)
}
quantity ::= integer(f) Feet integer(i_int) fraction(i_frac). {
    return .quantity((f * 12 + i_int) * i_frac.1 + i_frac.0, i_frac.1)
}
quantity ::= integer(f) Feet integer(i_int) Inches. {
    return .quantity(f * 12 + i_int, 1)
}
quantity ::= integer(f) Feet integer(i_int). {
    return .quantity(f * 12 + i_int, 1)
}
quantity ::= integer(f) Feet fraction(i_frac) Inches. {
    return .quantity(f * 12 * i_frac.1 + i_frac.0, i_frac.1)
}
quantity ::= integer(f) Feet fraction(i_frac). {
    return .quantity(f * 12 * i_frac.1 + i_frac.0, i_frac.1)
}
quantity ::= integer(f) Feet. {
    return .quantity(f * 12, 1)
}
quantity ::= integer(i_int) fraction(i_frac) Inches. {
    return .quantity(i_int * i_frac.1 + i_frac.0, i_frac.1)
}
quantity ::= integer(i_int) fraction(i_frac). {
    return .quantity(i_int * i_frac.1 + i_frac.0, i_frac.1)
}
quantity ::= integer(i_int) Inches. {
    return .quantity(i_int, 1)
}
quantity ::= integer(i_int). {
    return .quantity(i_int, 1)
}
quantity ::= fraction(i_frac) Inches. {
    return .quantity(i_frac.0, i_frac.1)
}
quantity ::= fraction(i_frac). {
    return .quantity(i_frac.0, i_frac.1)
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
    if case .fraction(let num, let den) = x {
        return (num, den)
    } else {
        preconditionFailure("lexer did not return Token.fraction for the Fraction token")
    }
}

%left_associative Add Subtract.
%left_associative Multiply Divide.
