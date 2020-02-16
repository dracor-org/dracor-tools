<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <!-- We use indent=no to prevent Saxon to add unnecessary newlines. -->
  <xsl:output
    method="xml"
    encoding="UTF-8"
    omit-xml-declaration="no"
    indent="no"
  />

  <!-- Biblioteca italiana ID -->
  <xsl:variable
    name="idno"
    select="/tei:TEI//tei:publicationStmt/tei:idno[not(@type)][1]/text()"
  />
  <!-- div types we can translate to dracor types -->
  <xsl:variable
    name="types"
    select="tokenize('atto scena prologo prol epilogo epil parte dedica prefazione cast')"
  />
  <!-- cast list -->
  <xsl:variable name="castList" select="/tei:TEI//tei:castList"/>

  <xsl:template match="/">
    <xsl:apply-templates select="/tei:TEI"/>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- set xml:lang -->
  <xsl:template match="tei:TEI[not(@xml:lang)]">
    <TEI xml:lang="ita">
      <xsl:apply-templates select="/tei:TEI/*"/>
    </TEI>
  </xsl:template>

  <!-- add digital source -->
  <xsl:template match="tei:sourceDesc[not(tei:bibl[@type='digitalSource'])]">
    <sourceDesc>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
      <bibl type="digitalSource">
        <name>Biblioteca Italiana</name>
        <idno type="URL">
          <xsl:text>http://www.bibliotecaitaliana.it/testo/</xsl:text>
          <xsl:value-of select="$idno"/>
        </idno>
      </bibl>
    </sourceDesc>
  </xsl:template>

  <!-- transform numbered divs with types having no DraCor equivalent -->
  <!-- (sezione arg introduzione premessa poesia canzone) -->
  <xsl:template match="(tei:div1|tei:div2|tei:div3)">
    <div>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- match div types -->
  <xsl:template
    match="(tei:div|tei:div1|tei:div2|tei:div3)[lower-case(@type) = $types]"
  >
    <xsl:variable name="type" select="lower-case(@type)"/>
    <div>
      <!--
        atto scena prologo prol epilogo epil parte dedica cast prefazione
      -->
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="$type = 'atto'">
            <xsl:text>act</xsl:text>
          </xsl:when>
          <xsl:when test="$type = 'scena'">
            <xsl:text>scene</xsl:text>
          </xsl:when>
          <xsl:when test="$type = 'parte'">
            <xsl:text>part</xsl:text>
          </xsl:when>
          <xsl:when test="$type = 'prologo' or $type = 'prol'">
            <xsl:text>prologue</xsl:text>
          </xsl:when>
          <xsl:when test="$type = 'epilogo' or $type = 'epil'">
            <xsl:text>epilogue</xsl:text>
          </xsl:when>
          <xsl:when test="$type = 'prefazione'">
            <xsl:text>preface</xsl:text>
          </xsl:when>
          <xsl:when test="$type = 'dedica'">
            <xsl:text>dedication</xsl:text>
          </xsl:when>
          <xsl:when test="$type = 'cast'">
            <xsl:text>Dramatis_Personae</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="@*[local-name() != 'type']"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- add @type where @n has a DraCor type equivalent -->
  <xsl:template
    match="(tei:div|tei:div1|tei:div2|tei:div3)[not(@type) and @n]"
  >
    <xsl:variable name="n" select="lower-case(@n)"/>
    <div>
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="starts-with($n, 'atto')">
            <xsl:text>act</xsl:text>
          </xsl:when>
          <xsl:when test="starts-with($n, 'scena')">
            <xsl:text>scene</xsl:text>
          </xsl:when>
          <xsl:when test="starts-with($n, 'parte')">
            <xsl:text>part</xsl:text>
          </xsl:when>
          <xsl:when test="starts-with($n, 'prologo')">
            <xsl:text>prologue</xsl:text>
          </xsl:when>
          <xsl:when test="starts-with($n, 'epilogo')">
            <xsl:text>epilogue</xsl:text>
          </xsl:when>
          <xsl:when test="starts-with($n, 'prefazione')">
            <xsl:text>preface</xsl:text>
          </xsl:when>
          <xsl:when test="starts-with($n, 'dedica')">
            <xsl:text>dedication</xsl:text>
          </xsl:when>
          <xsl:when test="starts-with($n, 'cast')">
            <xsl:text>Dramatis_Personae</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="@*[local-name() != 'type']"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="tei:Xsp[tei:speaker]">
    <xsl:variable name="whos">
      <xsl:call-template name="speakers-to-ids">
        <xsl:with-param name="speakers">
          <xsl:value-of select="normalize-space(tei:speaker)"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <sp>
      <xsl:attribute name="who">
        <xsl:value-of select="$whos"/>
      </xsl:attribute>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </sp>
  </xsl:template>

  <xsl:template name="speakers-to-ids">
    <xsl:param name="speakers"/>
    <xsl:variable name="tokens" select="tokenize($speakers, ',\s*')"/>
    <xsl:for-each select="$tokens">
      <xsl:sequence
        select="concat(lower-case(.), ' '[not(last())])"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="normal-case">
    <xsl:param name="string"/>
    <xsl:choose>
      <xsl:when test="matches($string, '^[\p{Lu}\s]+$', '')">
        <xsl:variable name="tokens" select="tokenize($string, '\s')"/>
        <xsl:for-each select="$tokens">
          <xsl:sequence
            select="concat(upper-case(substring(.,1,1)), lower-case(substring(., 2)), ' '[not(last())])"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
