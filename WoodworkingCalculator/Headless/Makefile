PARSER_PATH = ../Parser
GRAMMAR = WoodworkingCalculatorGrammar

build: main

${PARSER_PATH}/${GRAMMAR}.swift: ${PARSER_PATH}/${GRAMMAR}.y
	cd ${PARSER_PATH} && make ${GRAMMAR}.swift

main: ${PARSER_PATH}/CitronLexer.swift ${PARSER_PATH}/CitronParser.swift ${PARSER_PATH}/${GRAMMAR}.swift ${PARSER_PATH}/WoodworkingCalculatorParser.swift ./main.swift
	swiftc ${PARSER_PATH}/CitronLexer.swift ${PARSER_PATH}/CitronParser.swift ${PARSER_PATH}/${GRAMMAR}.swift ${PARSER_PATH}/WoodworkingCalculatorParser.swift ./main.swift -o main

