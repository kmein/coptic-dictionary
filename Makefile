.PHONY: all
all: coptic-dictionary.pdf

.PHONY: clean
clean:
	rm Comprehensive_Coptic_Lexicon-v1.2-2020.xml coptic-dictionary.pdf entries.typ

Comprehensive_Coptic_Lexicon-v1.2-2020.xml:
	wget -O $@ https://refubium.fu-berlin.de/bitstream/handle/fub188/27813/Comprehensive_Coptic_Lexicon-v1.2-2020.xml?sequence=1&isAllowed=y&save=y

coptic-dictionary.pdf: coptic-dictionary.typ entries.typ
	typst compile $<

.PHONY: view
view: coptic-dictionary.pdf
	zathura $<

entries.typ: Comprehensive_Coptic_Lexicon-v1.2-2020.xml tei2typst.xslt
	saxonb -s:$< -xsl:tei2typst.xslt -o:$@

coptic.babylon: Comprehensive_Coptic_Lexicon-v1.2-2020.xml tei2babylon.xslt
	saxonb -s:$< -xsl:tei2babylon.xslt -o:$@

.PHONY: stardict
stardict: coptic.babylon
	babylon $<
