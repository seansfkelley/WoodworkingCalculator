GRAMMAR = WoodworkingCalculatorGrammar

build: main

../Parser/${GRAMMAR}.swift: ../Parser/${GRAMMAR}.y
	cd ../Parser && make ${GRAMMAR}.swift

main: ../Parser/CitronLexer.swift ../Parser/CitronParser.swift ../Parser/${GRAMMAR}.swift ../Parser/WoodworkingCalculatorParser.swift ../Rational.swift ./main.swift
	swiftc ../Parser/CitronLexer.swift ../Parser/CitronParser.swift ../Parser/${GRAMMAR}.swift ../Parser/WoodworkingCalculatorParser.swift ../Rational.swift ./main.swift -o main

