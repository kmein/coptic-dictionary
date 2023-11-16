import csv
import re
import xml.etree.ElementTree as ET

namespaces = {
    "": "http://www.tei-c.org/ns/1.0",
    "custom": "http://www.tei-c.org/ns/1.0",
    "xml": "http://www.w3.org/XML/1998/namespace",
}

coptic_dictionary_xml_path = "/nix/store/1lz3igf9xyjff54jhbag5hmafcj322bv-source/xml/Comprehensive_Coptic_Lexicon-v1.2-2020.xml"
threshold = 5
preferred_language = "en"

tree = ET.parse(coptic_dictionary_xml_path)

def all_words():
    with open(file="frequency.csv") as csv_file:
        reader = csv.reader(csv_file, delimiter="\t")
        for word, frequency in reader:
            try:
                if int(frequency) >= threshold:
                    yield word
            except:
                pass

def lookup_word(word):
    entries = []
    for entry in tree.findall(".//entry", namespaces):
        for form in entry.findall(".//orth", namespaces):
            if form.text == word:
                meanings = []
                for sense in entry.findall(f"./sense/cit/quote[@xml:lang='{preferred_language}']", namespaces):
                    meanings.append(re.sub(r"\s+", " ", sense.text or ""))
                if len(meanings) > 0 and meanings not in entries:
                    entries.append(meanings)
    return entries

for word in all_words():
    meanings = lookup_word(word)
    if len(meanings) > 0:
        print(word, "; ".join(", ".join(group) for group in meanings))
