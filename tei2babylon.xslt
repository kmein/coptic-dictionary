<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <xsl:output media-type="text/typst" omit-xml-declaration="yes"/>

  <!-- ref https://gist.github.com/fidothe/9da736aadee12629f5df -->
  <xsl:template name="encode-string"> <xsl:param name="s" select="''"/><xsl:value-of select="string-join(replace($s, '\s+', ' '), '; ')"/></xsl:template>

  <xsl:template name="encode-array"> <xsl:param name="element" select="''"/><xsl:for-each select="$element"> <xsl:apply-templates select="."/> <xsl:if test="position() != last() or count($element) = 0">, </xsl:if> </xsl:for-each></xsl:template>

  <xsl:template name="encode-alternatives"> <xsl:param name="element" select="''"/><xsl:for-each select="$element"> <xsl:apply-templates select="."/> <xsl:if test="position() != last() or count($element) = 1">|</xsl:if> </xsl:for-each></xsl:template>

  <xsl:template match="tei:note | tei:gram | tei:subc | tei:ref[@type='Greek'] | tei:def[@xml:lang] | tei:quote"> <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="."/> </xsl:call-template> </xsl:template>


  <xsl:template match="tei:etym"></xsl:template>
    <!--
    notes: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:note"/> </xsl:call-template>
    references: <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:xr/tei:ref"/> </xsl:call-template>
    equivalentGreek: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type=Greek]"/> </xsl:call-template>
    greekLemma: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type='greek_lemma::grl_lemma']"/> </xsl:call-template>
    greekMeaning: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type='greek_lemma::grl_meaning']"/> </xsl:call-template>
    greekPartOfSpeech: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type='greek_lemma::grl_pos']"/> </xsl:call-template>
    greekReference: <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:ref[@type='greek_lemma::grl_ref']"/> </xsl:call-template>
    -->

  <xsl:template match="tei:ref"></xsl:template>

  <xsl:template match="tei:cit">
    <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:quote[@xml:lang='en']"/> </xsl:call-template> <!--/ <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:quote[not(@xml:lang)]"/> </xsl:call-template> / <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:def[@xml:lang='en']"/> </xsl:call-template> [<xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:bibl"/> </xsl:call-template>]-->
  </xsl:template>

  <xsl:template match="tei:sense"> <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:cit"/> </xsl:call-template> <xsl:if test="tei:ref[@type='Greek']"><xsl:text> </xsl:text>(<xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:ref[@type='Greek']"/></xsl:call-template>)</xsl:if></xsl:template>

  <xsl:template match="tei:entry">
    <xsl:call-template name="encode-alternatives"><xsl:with-param name="element" select="tei:form"/></xsl:call-template><xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="tei:gramGrp"/><xsl:if test="not(tei:gramGrp)"></xsl:if>
    <xsl:call-template name="encode-array"><xsl:with-param name="element" select="tei:sense"/></xsl:call-template> <xsl:text>&#xa;&#xa;</xsl:text>
  </xsl:template>

  <xsl:template match="tei:gramGrp">
    <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:pos"/> </xsl:call-template><xsl:text> </xsl:text> <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:subc"/> </xsl:call-template> <xsl:text> </xsl:text> <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:gen"/> </xsl:call-template> <xsl:text> </xsl:text> <xsl:call-template name="encode-array"> <xsl:with-param name="element" select="tei:gram"/> </xsl:call-template> <xsl:text> </xsl:text> <xsl:call-template name="encode-string"> <xsl:with-param name="s" select="tei:number"/> </xsl:call-template></xsl:template>

<xsl:template match="tei:form"><xsl:call-template name="encode-string"><xsl:with-param name="s" select="tei:orth"/></xsl:call-template></xsl:template>

<xsl:template match="/">
  <xsl:apply-templates select="//tei:entry"/>
</xsl:template>
</xsl:stylesheet>
