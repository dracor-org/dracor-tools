<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:functx="http://www.functx.com"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="tei xs functx">

  <xsl:function name="functx:substring-after-if-contains" as="xs:string?">
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:param name="delim" as="xs:string"/>
    <xsl:sequence select="
     if (contains($arg,$delim))
     then substring-after($arg,$delim)
     else $arg
   "/>
  </xsl:function>

  <xsl:function name="functx:name-test" as="xs:boolean">
    <xsl:param name="testname" as="xs:string?"/>
    <xsl:param name="names" as="xs:string*"/>
    <xsl:sequence select="
  $testname = $names
  or
  $names = '*'
  or
  functx:substring-after-if-contains($testname,':') =
     (for $name in $names
     return substring-after($name,'*:'))
  or
  substring-before($testname,':') =
     (for $name in $names[contains(.,':*')]
     return substring-before($name,':*'))
   "/>
  </xsl:function>

  <xsl:function name="functx:remove-elements-deep" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="names" as="xs:string*"/>

     <xsl:for-each select="$nodes">
       <xsl:choose>
         <xsl:when test=". instance of element()">
           <xsl:if test="not(functx:name-test(name(),$names))">
             <xsl:element name="{node-name(.)}">
               <xsl:sequence select="@*,
                    functx:remove-elements-deep(node(), $names)"/>
             </xsl:element>
           </xsl:if>
         </xsl:when>
         <xsl:when test=". instance of document-node()">
           <xsl:document>
               <xsl:sequence select="
                    functx:remove-elements-deep(node(), $names)"/>
           </xsl:document>
         </xsl:when>
         <xsl:otherwise>
           <xsl:sequence select="."/>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:for-each>

  </xsl:function>
  
  <!-- We use indent=no to prevent Saxon to add unnecessary newlines. -->
  <xsl:output
    method="xml"
    encoding="UTF-8"
    omit-xml-declaration="no"
    indent="no"
  />

  <xsl:variable name="plays" select="document('ident.xml')"/>
  <xsl:variable name="dracor-id" select="/tei:TEI//tei:publicationStmt/tei:idno[@type='dracor']/text()"/>
  <xsl:variable name="play" select="document('ident.xml')//play[@id=$dracor-id]"/>
  

  <xsl:template match="/">
    <xsl:apply-templates select="/tei:TEI"/>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- create particDesc -->
  <xsl:template match="tei:profileDesc">
    <profileDesc>
      <xsl:apply-templates/>
      <xsl:if test="$play">
        <particDesc>
          <listPerson>
            <xsl:for-each select="$play//speakers/s[@label]">
              <xsl:variable name="s" select="."/>
              <xsl:variable name="id">
                <xsl:choose>
                  <xsl:when test="./@id">
                    <xsl:value-of select="./@id/string()"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="replace(., ' ', '_')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="@group">
                  <personGrp xml:id="{$id}">
                    <name>
                      <xsl:value-of select="@label/string()"/>
                    </name>
                  </personGrp>
                </xsl:when>
                <xsl:otherwise>
                  <person xml:id="{$id}">
                    <persName>
                      <xsl:value-of select="@label/string()"/>
                    </persName>
                  </person>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text>&#10;</xsl:text>
            </xsl:for-each>
          </listPerson>
        </particDesc>
      </xsl:if>
    </profileDesc>
  </xsl:template>

  <xsl:template match="tei:sp[not(@who) and tei:speaker]">
    <xsl:variable name="s" select="."/>
    <sp>
      <xsl:attribute name="who">
        <xsl:call-template name="who">
          <xsl:with-param name="speaker-text">
            <xsl:message>
              <xsl:value-of select="functx:remove-elements-deep(tei:speaker, '*:note')"/>
            </xsl:message>
            <xsl:value-of select="normalize-space(functx:remove-elements-deep(tei:speaker, '*:note'))"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates/>
    </sp>
  </xsl:template>

  <xsl:template name="who">
    <xsl:param name="speaker-text"/>
    <!-- <xsl:message><xsl:value-of select="$speaker-text"/></xsl:message> -->
    <xsl:variable name="refs">
      <xsl:for-each select="tokenize($speaker-text, '( e .l |\W[eE][dD]?\W|, +)')">
        <xsl:variable name="name"
          select="normalize-space(lower-case(replace(., '[\[\]{}&lt;>.;,:]', '')))"
        />
        <xsl:variable name="match" select="$play//speakers/s[. = $name]"/>
        <xsl:choose>
          <xsl:when test="$match[@ref]">
            <xsl:value-of select="concat($match/@ref/string(), ' ')"/>
          </xsl:when>
          <xsl:when test="$match[@id]">
            <xsl:value-of select="concat('#', $match/@id/string(), ' ')"/>
          </xsl:when>
          <xsl:when test="$match">
            <xsl:value-of select="concat('#', replace($name, ' ', '_'), ' ')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('#', $name, ' ')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="normalize-space($refs)"/>
  </xsl:template>
</xsl:stylesheet>
