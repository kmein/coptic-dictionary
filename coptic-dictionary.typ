#{
  import "entries.typ": entries

  let enum_if_multiple(function, list) = {
    if list.len() == 1 {
      function(list.at(0))
    } else {
      list.enumerate().map(pair => {
      let (index, value) = pair
      [#(index + 1).#sym.space.nobreak #function(value)]
      }).join(" ")
    }
  }

  let non_empty = x => x != "" and x != none

  let fmap(function, value) = {
    if non_empty(value) {
      function(value)
    }
  }

  let parenthesize = (body) => "(" + body + ")"
  let bracket = (body) => "[" + body + "]"
  let enquote = (body) => sym.quote.l.single + body + sym.quote.r.single

  let render_reference(body) = text(size: 0.7em, fill: gray, body)

  let render_grammar(gram) = {
    emph((gram.partOfSpeech, gram.subCategories.join(", "), gram.gender, gram.number, gram.grammar.join(", "), fmap(parenthesize, gram.notes.join(", "))).filter(non_empty).join(" "))
  }

  let render_form(form) = {
    super(form.usage) + text(
      fill: if (form.type == "lemma") {
        black
      } else if (form.type == "inflected") {
        maroon
      } else {
        blue
      },
      form.orthography + " " + fmap(render_grammar,form.grammar)
    )
  }

  let render_sense(sense) = {
    ( sense.equivalentGreek.join(", ")
    , sense.citations.map(cit =>
        text(
          fill: if cit.type == "example" { olive } else {black},
          (
            if cit.quoteDE.len() > 0 {
              cit.quoteDE.join("; ")
            } else if cit.quoteEN.len() > 0 {
              cit.quoteEN.join("; ")
            } else {
              cit.quote.join("; ")
            },
            if cit.definitionDE.len() > 0 {
              cit.definitionDE.join("; ")
            } else {
              cit.definitionEN.join("; ")
            }
          ).filter(non_empty).join([ #sym.slash ])
        )
        + fmap(x => " " + x, render_reference(cit.bibl))
      ).join([#sym.compose ])
    ).filter(non_empty).join([ #sym.slash ])
  }

  let render_etym(etym) = {
    let greek_etymology = (etym.greekLemma, fmap(emph, etym.greekPartOfSpeech), fmap(enquote, etym.greekMeaning), fmap(render_reference, etym.greekReference)).filter(non_empty).join(" ")
    fmap(bracket, (greek_etymology, etym.notes.join(", ")).filter(non_empty).join(" — "))
  }


  let render_entry(entry) = {
    let lemma = entry.forms.find(form => form.type == "lemma")
    terms(
      tight: true,
      hanging-indent: 0mm,
      (if non_empty(lemma) { [#text(lemma.orthography) #label(lemma.orthography)] } else { "—" }
      , ( entry.forms.filter(form => form.type != "lemma").map(render_form).join(" ")
        , fmap(render_grammar, entry.grammar)
        , entry.senses.map(render_sense).join([ #sym.lozenge.stroked ])
        , fmap(render_etym, entry.etym)
        , fmap(x => [#sym.arrow.r #x], entry.references.map(x => /*ref(label(*/x.target.replace(regex("^#"),"")/*))*/).join(", "))
        ).filter(non_empty).join(" ")
      )
    )
  }

  show par: set block(spacing: 0mm)
  set page(columns: 4, margin: 5%, flipped: true)
  set columns(gutter: 5pt)
  set text(10pt, lang:"de", hyphenate: auto)

  for entry in entries {
    render_entry(entry)
  }
}
