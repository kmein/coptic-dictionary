import xml.etree.ElementTree as ET
from typing import Optional, List, Literal, Dict
from typing import NamedTuple
from sys import stderr

input_path = "Comprehensive_Coptic_Lexicon-v1.2-2020.xml"
preferred_language = "de"


def fmap(function, value):
    try:
        return function(value)
    except:
        return None


Typst = str

tree = ET.parse(input_path)
root = tree.getroot()


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
    quote: str
    def_: str
    bibl: str


class Sense(NamedTuple):
    ref_greek: List[str]
    cit: List[Cit]


class CrossReference(NamedTuple):
    type_: Literal["cf", "syn"]
    target: str
    text: str


class Entry(NamedTuple):
    forms: List[Form]
    gram: Optional[Grammar]
    etym: Optional[Etymology]
    note: Optional[str]
    sense: List[Sense]
    xr: List[CrossReference]


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
        lambda x: x.text.replace("\n", " "),
        etym_xml.find("./ref[@type='greek_lemma::grl_lemma']", namespaces),
    )
    greek_pos = fmap(
        lambda x: x.text.replace("\n", " "),
        etym_xml.find("./ref[@type='greek_lemma::grl_pos']", namespaces),
    )
    greek_ref = fmap(
        lambda x: x.text.replace("\n", " "),
        etym_xml.find("./ref[@type='greek_lemma::grl_ref']", namespaces),
    )
    greek_meaning = fmap(
        lambda x: x.text.replace("\n", " "),
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
        lambda n: n.text,
        cit_xml.find("./def[@xml:lang='" + preferred_language + "']", namespaces),
    ) or fmap(
        lambda n: n.text,
        cit_xml.find("./def[@xml:lang='" + preferred_language + "']", namespaces),
    )
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


def parse_xr(xr_xml: ET.Element) -> CrossReference:
    type_ = xr_xml.attrib["type"]
    ref = xr_xml.find("./ref", namespaces)
    target = ref.attrib["target"].lstrip("#")
    text = ref.text
    return CrossReference(type_=type_, target=target, text=text)


def parse_entry(entry_xml: ET.Element) -> Entry:
    forms = [parse_form(form) for form in entry_xml.findall("./form", namespaces)]
    gram = fmap(parse_gram, entry_xml.find("./gramGrp", namespaces))
    etym = fmap(parse_etym, entry_xml.find("./etym", namespaces))
    sense = [parse_sense(sense) for sense in entry_xml.findall("./sense", namespaces)]
    xr = [parse_xr(xr) for xr in entry_xml.findall("./xr", namespaces)]
    note = fmap(lambda n: n.text, entry_xml.find("./note", namespaces))
    return Entry(forms=forms, gram=gram, etym=etym, note=note, sense=sense, xr=xr)


def encode_list(xs):
    list_xs = list(xs)
    return "(" + ", ".join(list_xs) + ("," if len(list_xs) == 1 else "") + ")"


encode_dict = (
    lambda **d: "(" + ", ".join(f"{key}: {value}" for key, value in d.items()) + ")"
)
encode_string = (
    lambda s: ('"' + s.translate(str.maketrans({"\n": " ", '"': r"\""})) + '"')
    if s
    else "none"
)


def encode_form(form) -> Typst:
    return encode_dict(
        ref=encode_list(form.ref),
        usg=encode_string(form.usg),
        orth=encode_string(form.orth),
        oRef=encode_string(form.oRef),
        grammar=fmap(encode_gram, form.grammar) or "none",
        note=encode_string(form.note),
        type=encode_string(form.type_),
    )


def encode_gram(gram) -> Typst:
    return encode_dict(
        pos=encode_string(gram.pos),
        subc=encode_string(gram.subc),
        gen=encode_string(gram.gen),
        number=encode_string(gram.number),
        gram=encode_string(gram.gram),
        note=encode_string(gram.note),
    )


def encode_etym(etym) -> Typst:
    return encode_dict(
        note=encode_string(etym.note),
        greek_lemma=encode_string(etym.greek_lemma),
        greek_pos=encode_string(etym.greek_pos),
        greek_ref=encode_string(etym.greek_ref),
        greek_meaning=encode_string(etym.greek_meaning),
    )


def encode_cit(cit) -> Typst:
    return encode_dict(
        quote=encode_string(cit.quote),
        def_=encode_string(cit.def_),
        bibl=encode_string(cit.bibl),
        type=encode_string(cit.type_),
    )


def encode_sense(sense) -> Typst:
    return encode_dict(
        ref_greek=encode_list(
            encode_string(ref_greek) for ref_greek in sense.ref_greek
        ),
        cit=encode_list(encode_cit(cit) for cit in sense.cit),
    )


def encode_xr(xr) -> Typst:
    return encode_dict(
        type=encode_string(xr.type_),
        target=encode_string(xr.target),
        text=encode_string(xr.text),
    )


def encode_entry(entry) -> Typst:
    return encode_dict(
        forms=encode_list(encode_form(form) for form in entry.forms),
        gram=fmap(encode_gram, entry.gram) or "none",
        etym=fmap(encode_etym, entry.etym) or "none",
        sense=encode_list(encode_sense(sense) for sense in entry.sense),
        xr=encode_list(encode_xr(xr) for xr in entry.xr),
        note=encode_string(entry.note),
    )


if __name__ == "__main__":
    print(
        "#let entries =",
        encode_list(
            [
                encode_entry(parse_entry(e))
                for e in root.iterfind(".//entry", namespaces)
            ]
        ),
    )
else:
    global entries
    entries = [parse_entry(e) for e in root.findall(".//entry", namespaces)]
