GRAMMAR = WoodworkingCalculatorGrammar

build: main

../Parser/${GRAMMAR}.swift: ../Parser/${GRAMMAR}.y
	cd ../Parser && make ${GRAMMAR}.swift

main: ../Parser/CitronLexer.swift ../Parser/CitronParser.swift ../Parser/${GRAMMAR}.swift ../Parser/WoodworkingCalculatorParser.swift ../Fraction.swift ./main.swift
	swiftc ../Parser/CitronLexer.swift ../Parser/CitronParser.swift ../Parser/${GRAMMAR}.swift ../Parser/WoodworkingCalculatorParser.swift ../Fraction.swift ./main.swift -o main

