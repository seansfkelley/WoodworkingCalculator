build: main

../Parser/WoodworkingCalculatorParser.swift: ../Parser/WoodworkingCalculatorParser.y
	cd ../Parser && make WoodworkingCalculatorParser.swift

main: ../Parser/CitronLexer.swift ../Parser/CitronParser.swift ../Parser/WoodworkingCalculatorParser.swift ./main.swift
	swiftc ../Parser/CitronLexer.swift ../Parser/CitronParser.swift ../Parser/WoodworkingCalculatorParser.swift ./main.swift -o main

