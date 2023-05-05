.PHONY: all
all: coptic-dictionary.pdf

Comprehensive_Coptic_Lexicon-v1.2-2020.xml:
	wget -O $@ https://refubium.fu-berlin.de/bitstream/handle/fub188/27813/Comprehensive_Coptic_Lexicon-v1.2-2020.xml?sequence=1&isAllowed=y&save=y

entries.typ: Comprehensive_Coptic_Lexicon-v1.2-2020.xml convert.py
	python3 convert.py > $@

coptic-dictionary.pdf: coptic-dictionary.typ entries.typ
	typst compile $<

.PHONY: view
view: coptic-dictionary.pdf
	zathura $<
