#{
  import "entries.typ": entries

  let transliterate = coptic => coptic
    .replace("ⲁ", "a")
    .replace("ⲃ", "b")

  let enum_if_multiple(function, list) = {
    if list.len() == 1 {
      function(list.at(0))
    } else {
      list.enumerate().map(pair => {
      let (index, value) = pair
      str(index + 1) + ". " + function(value)
      }).join(" ")
      /* enum(list.map(function).enumerate()) */
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
  let enquote = (body) => "\"" + body + "\""

  let render_reference(body) = text(size: 0.7em, fill: gray, body)

  let render_grammar(gram) = {
    emph((gram.pos, gram.subc, gram.gen, gram.number, gram.gram, fmap(parenthesize, gram.note)).filter(non_empty).join(" "))
  }

  let render_form(form) = {
    super(form.usg) + text(
      fill: if (form.type == "lemma") {
        black
      } else if (form.type == "inflected") {
        aqua
      } else {
        blue
      },
      form.orth + " " + fmap(render_grammar,form.grammar)
    )
  }

  let render_sense(sense) = {
    ( sense.ref_greek.join(", ")
    , sense.cit.map(cit =>
        text(fill: if cit.type == "example" { olive } else {black},(cit.quote, cit.def_).filter(non_empty).join([ #sym.slash ]))
        + fmap(x => " " + x, render_reference(cit.bibl))
      ).join([#sym.compose ])
    ).filter(non_empty).join([ #sym.lozenge.stroked ])
  }

  let render_etym(etym) = {
    let greek_etymology = (etym.greek_lemma, fmap(emph, etym.greek_pos), fmap(enquote, etym.greek_meaning), fmap(render_reference, etym.greek_ref)).filter(non_empty).join(" ")
    fmap(bracket, (greek_etymology, etym.note).filter(non_empty).join(" — "))
  }


  let render_entry(entry) = {
    let lemma = entry.forms.find(form => form.type == "lemma")
    terms(
      tight: true,
      hanging-indent: 0mm,
      (if non_empty(lemma) { [#text(lemma.orth) #label(lemma.orth)] } else { "—" },
        ( entry.forms.filter(form => form.type != "lemma").map(render_form).join(" ")
        , fmap(render_grammar, entry.gram)
        , enum_if_multiple(render_sense, entry.sense)
        , fmap(render_etym, entry.etym)
        , fmap(x => [#sym.arrow.r #x], entry.xr.map(x => /*ref(label(*/x.target/*))*/).join(", "))
        ).filter(non_empty).join(" ")
      )
    )
  }

  show par: set block(spacing: 0mm)
  set page(columns: 3, margin: 5%)
  set text(10pt)

  for entry in entries {
    render_entry(entry)
  }
}
