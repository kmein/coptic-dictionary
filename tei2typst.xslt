<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <xsl:output media-type="text/typst" omit-xml-declaration="yes"/>

  <!-- ref https://gist.github.com/fidothe/9da736aadee12629f5df -->
  <xsl:template name="encode-string"> <xsl:param name="s" select="''"/> "<xsl:value-of select="replace(replace(string-join($s, '; '), '&quot;', '\\&quot;'), '&#xA;', ' ')"/>" </xsl:template>

  <xsl:template name="encode-array"> <xsl:param name="element" select="()"/> (<xsl:for-each select="$element"> <xsl:apply-templates select="."/> <xsl:if test="position() != last() or count($element) = 1">, </xsl:if> </xsl:for-each>) </xsl:template>

  <xsl:template match="tei:note | tei:gram | tei:subc | tei:ref[@type='Greek'] | tei:def[@xml:lang] | tei:quote"> <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="."/> </xsl:call-template> </xsl:template>


  <xsl:template match="tei:etym">( notes: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:note"/> </xsl:call-template> , references: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:xr/tei:ref"/> </xsl:call-template> , equivalentGreek: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type=Greek]"/> </xsl:call-template> , greekLemma: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type='greek_lemma::grl_lemma']"/> </xsl:call-template> , greekMeaning: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type='greek_lemma::grl_meaning']"/> </xsl:call-template> , greekPartOfSpeech: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type='greek_lemma::grl_pos']"/> </xsl:call-template> , greekReference: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type='greek_lemma::grl_ref']"/> </xsl:call-template>)</xsl:template>

  <xsl:template match="tei:ref"> ( target: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="@target"/> </xsl:call-template> , reference: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="."/> </xsl:call-template>) </xsl:template>

  <xsl:template match="tei:cit"> ( bibl: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:bibl"/> </xsl:call-template> , type: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="@type"/> </xsl:call-template>, quoteDE: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:quote[@xml:lang='de']"/> </xsl:call-template>, quoteEN: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:quote[@xml:lang='en']"/> </xsl:call-template> , quoteFR: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:quote[@xml:lang='fr']"/> </xsl:call-template>, quote: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:quote[not(@xml:lang)]"/> </xsl:call-template>, definitionDE: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:def[@xml:lang='de']"/> </xsl:call-template> , definitionEN: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:def[@xml:lang='en']"/> </xsl:call-template> , definitionFR: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:def[@xml:lang='fr']"/> </xsl:call-template>) </xsl:template>

  <xsl:template match="tei:sense"> ( equivalentGreek: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:ref[@type='Greek']"/> </xsl:call-template> , citations: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:cit"/> </xsl:call-template>) </xsl:template>

  <xsl:template match="tei:entry">
    ( id: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="@xml:id"/> </xsl:call-template> , forms: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:form"/> </xsl:call-template> , grammar: <xsl:apply-templates select="tei:gramGrp"/><xsl:if test="not(tei:gramGrp)">""</xsl:if> , etym: <xsl:apply-templates select="tei:etym"/><xsl:if test="not(tei:etym)">""</xsl:if> , senses: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:sense"/> </xsl:call-template> , references: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:xr/tei:ref"/> </xsl:call-template>)
  </xsl:template>

  <xsl:template match="tei:gramGrp"> ( partOfSpeech: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:pos"/> </xsl:call-template> , subCategories: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:subc"/> </xsl:call-template> , gender: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:gen"/> </xsl:call-template> , grammar: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:gram"/> </xsl:call-template> , number: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:number"/> </xsl:call-template> , notes: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:note"/> </xsl:call-template>) </xsl:template>

  <xsl:template match="tei:form"> ( type: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="@type"/> </xsl:call-template> , usage: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:usg[@type='geo']"/> </xsl:call-template> , orthography: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:orth"/> </xsl:call-template> , grammar: <xsl:apply-templates select="tei:gramGrp"/><xsl:if test="not(tei:gramGrp)">""</xsl:if>) </xsl:template>

  <xsl:template match="/">#let entries = (
    <xsl:call-template name="encode-array">
      <xsl:with-param name="element" select="//tei:entry"/>
    </xsl:call-template>)</xsl:template>
</xsl:stylesheet>
