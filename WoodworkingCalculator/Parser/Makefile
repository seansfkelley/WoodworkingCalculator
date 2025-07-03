GRAMMAR = WoodworkingCalculatorGrammar
CITRON_SRC = citron.c
CITRON = citron

build: ${CITRON} ${GRAMMAR}.swift

clean:
	rm ${NAME}

${CITRON}: ${CITRON_SRC}
	clang ${CITRON_SRC} -o ${CITRON}

${GRAMMAR}.swift: ${CITRON} ${GRAMMAR}.y
	./${CITRON} ${GRAMMAR}.y -o ${GRAMMAR}.swift
