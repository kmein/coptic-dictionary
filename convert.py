import xml.etree.ElementTree as ET
from typing import Optional, List, Literal, Dict
from typing import NamedTuple

input_path = "Comprehensive_Coptic_Lexicon-v1.2-2020.xml"


def fmap(function, value):
    try:
        return function(value)
    except:
        return None


tree = ET.parse(input_path)
root = tree.getroot()

Language = Literal["en", "de", "fr"]


class Grammar(NamedTuple):
    pos: str
    subc: Optional[str]
    gen: Optional[str]
    gram: Optional[str]
    number: Optional[str]
    note: Optional[str]


class Form(NamedTuple):
    ref: List[str]
    usg: Optional[str]
    orth: Optional[str]
    oRef: Optional[str]
    grammar: Optional[Grammar]
    note: Optional[str]
    type_: Optional[Literal["inflected", "lemma", "compound"]]


class Etymology(NamedTuple):
    note: Optional[str]
    greek_lemma: Optional[str]
    greek_pos: Optional[str]
    greek_ref: Optional[str]
    greek_meaning: Optional[str]


class Cit(NamedTuple):
    type_: Literal["example", "translation"]
    quote: str  # Dict[Language, str]
    def_: str
    bibl: str


class Sense(NamedTuple):
    ref_greek: List[str]
    cit: List[Cit]


class Entry(NamedTuple):
    forms: List[Form]
    gram: Optional[Grammar]
    etym: Optional[Etymology]
    note: Optional[str]
    sense: List[Sense]


namespaces = {
    "": "http://www.tei-c.org/ns/1.0",
    "custom": "http://www.tei-c.org/ns/1.0",
    "xml": "http://www.w3.org/XML/1998/namespace",
}


def parse_form(form_xml: ET.Element) -> Form:
    try:
        type_ = form_xml.attrib["type"]
    except KeyError:
        type_ = None
    usg = fmap(lambda n: n.text, form_xml.find("./usg", namespaces))
    orth = fmap(lambda n: n.text, form_xml.find("./orth", namespaces))
    oRef = fmap(lambda n: n.text, form_xml.find("./oRef", namespaces))
    note = fmap(lambda n: n.text, form_xml.find("./note", namespaces))
    gram = fmap(parse_gram, form_xml.find("./gramGrp", namespaces))
    ref = [ref.text or "" for ref in form_xml.findall("./ref", namespaces)]
    return Form(
        type_=type_
        if type_ == "lemma" or type_ == "inflected" or type_ == "compound"
        else None,
        usg=usg,
        orth=orth,
        oRef=oRef,
        ref=ref,
        grammar=gram,
        note=note,
    )


def parse_gram(gram_xml: ET.Element) -> Grammar:
    pos = fmap(lambda x: x.text, gram_xml.find("./pos", namespaces))
    gen = fmap(lambda x: x.text, gram_xml.find("./gen", namespaces))
    subc = fmap(lambda x: x.text, gram_xml.find("./subc", namespaces))
    gram = fmap(lambda x: x.text, gram_xml.find("./gram", namespaces))
    number = fmap(lambda x: x.text, gram_xml.find("./number", namespaces))
    note = fmap(lambda x: x.text, gram_xml.find("./note", namespaces))
    return Grammar(
        pos=pos or "?", subc=subc, gen=gen, gram=gram, number=number, note=note
    )


def parse_etym(etym_xml: ET.Element) -> Etymology:
    note = fmap(lambda x: x.text, etym_xml.find("./note", namespaces))
    greek_lemma = fmap(
        lambda x: x.text,
        etym_xml.find("./ref[@type='greek_lemma::grl_lemma']", namespaces),
    )
    greek_pos = fmap(
        lambda x: x.text,
        etym_xml.find("./ref[@type='greek_lemma::grl_pos']", namespaces),
    )
    greek_ref = fmap(
        lambda x: x.text,
        etym_xml.find("./ref[@type='greek_lemma::grl_ref']", namespaces),
    )
    greek_meaning = fmap(
        lambda x: x.text,
        etym_xml.find("./ref[@type='greek_lemma::grl_meaning']", namespaces),
    )
    return Etymology(
        note=note,
        greek_lemma=greek_lemma,
        greek_pos=greek_pos,
        greek_ref=greek_ref,
        greek_meaning=greek_meaning,
    )


def parse_cit(cit_xml: ET.Element) -> Cit:
    try:
        type_ = cit_xml.attrib["type"]
    except KeyError:
        type_ = None

    def_ = fmap(
        lambda n: n.text, cit_xml.find("./def[@xml:lang='de']", namespaces)
    ) or fmap(lambda n: n.text, cit_xml.find("./def[@xml:lang='en']", namespaces))
    if type_ == "translation":
        quote = fmap(
            lambda n: n.text, cit_xml.find("./quote[@xml:lang='de']", namespaces)
        ) or fmap(lambda n: n.text, cit_xml.find("./quote[@xml:lang='en']", namespaces))
    elif type_ == "example":
        quote = ", ".join(
            quote.text or "" for quote in cit_xml.findall("./quote", namespaces)
        )
    else:
        quote = ""
    bibl = fmap(lambda n: n.text, cit_xml.find("./bibl", namespaces))
    return Cit(
        type_=type_ if type_ == "translation" or type_ == "example" else "translation",
        quote=fmap(lambda x: x.replace("\n", " "), quote),
        def_=fmap(lambda x: x.replace("\n", " "), def_),
        bibl=bibl or "",
    )


def parse_sense(sense_xml: ET.Element) -> Sense:
    ref_greek = [
        ref.text or "" for ref in sense_xml.findall("./ref[@type='Greek']", namespaces)
    ]
    cit = [parse_cit(cit) for cit in sense_xml.findall("./cit", namespaces)]
    return Sense(ref_greek=ref_greek, cit=cit)


def parse_entry(entry_xml: ET.Element) -> Entry:
    forms = [parse_form(form) for form in entry_xml.findall("./form", namespaces)]
    gram = fmap(parse_gram, entry_xml.find("./gramGrp", namespaces))
    etym = fmap(parse_etym, entry_xml.find("./etym", namespaces))
    sense = [parse_sense(sense) for sense in entry_xml.findall("./sense", namespaces)]
    note = fmap(lambda n: n.text, entry_xml.find("./note", namespaces))
    return Entry(
        forms=forms,
        gram=gram,
        etym=etym,
        note=note,
        sense=sense,
    )


def render_gram(gram: Grammar) -> str:
    return (
        "_"
        + " ".join(
            x
            for x in [
                gram.pos,
                gram.subc,
                gram.gen,
                gram.number,
                gram.gram,
                "(" + gram.note.replace("*", "\\*") + ")" if gram.note else None,
            ]
            if x
        )
        + "_"
    )


def render_sense(sense: Sense) -> str:
    return (
        ", ".join(sense.ref_greek) + " --- " if sense.ref_greek else ""
    ) + "; ".join(
        " --- ".join(x for x in [cit.quote, cit.def_] if x)
        + f" #text(size: 0.7em, fill: gray)[{cit.bibl}]"
        for cit in sense.cit
    )


def render_etym(etym: Etymology) -> str:
    greek_etymology = (
        " ".join(
            x
            for x in [
                etym.greek_lemma,
                fmap(lambda x: f"_{x}_", etym.greek_pos),
                fmap(lambda x: f"'{x}'", etym.greek_meaning),
                fmap(lambda x: f"#text(size: 0.7em, fill: gray)[{x}]", etym.greek_ref),
            ]
            if x
        )
        if etym.greek_lemma or etym.greek_pos or etym.greek_meaning or etym.greek_ref
        else None
    )
    full_etymology = " -- ".join(
        etym for etym in [greek_etymology, fmap(str.strip, etym.note)] if etym
    )
    if full_etymology:
        return "[" + full_etymology + "]"
    else:
        return ""


def render_entry(entry: Entry) -> str:
    try:
        lemma = next(filter(lambda form: form.type_ == "lemma", entry.forms))
    except StopIteration:
        lemma = None
    forms = " ".join(
        f"#text(fill: {'black' if form.type_ == 'lemma' else 'olive' if form.type_ == 'inflected' else 'blue'})[#super[{form.usg}]\u200c"
        + form.orth.replace("*", "\\*")
        + (f" ({render_gram(form.grammar)})" if form.grammar else "")
        + "]"
        for form in entry.forms
        if form.type_ != "lemma"
    )
    senses = (
        "  " + render_sense(entry.sense[0])
        if len(entry.sense) == 1
        else " ".join(
            f"{index+1}. {render_sense(sense)}"
            for index, sense in enumerate(entry.sense)
        )
    )
    return (
        "/ "
        + (lemma.orth.replace("*", "\\*") if lemma else "---")
        + f": {forms} {render_gram(entry.gram) if entry.gram else ''} {senses} {render_etym(entry.etym) if entry.etym else ''}".replace(
            "`", "'"
        )
    )


if __name__ == "__main__":
    print(
        """
#set page(columns: 3, margin: 5%)
#set terms(tight: true, hanging-indent: 0mm)
#show par: set block(spacing: 0mm)
#set text(10pt)
    """
    )

    for e in root.iterfind(".//entry", namespaces):
        print(render_entry(parse_entry(e)))
else:
    global entries
    entries = [parse_entry(e) for e in root.findall(".//entry", namespaces)]
