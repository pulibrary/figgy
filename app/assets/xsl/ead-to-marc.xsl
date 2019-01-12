<?xml version="1.0" encoding="UTF-8"?>
<!-- author: Don Thornbury <doncat@princeton.edu> -->
<!-- December 26 2018 -->
<xsl:stylesheet version="1.0"
    xmlns:marc="https://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="urn:isbn:1-931666-22-9">
    <xsl:output indent="yes" method="xml"/>
    <xsl:preserve-space elements="leader"/>
    <xsl:preserve-space elements="controlfield"/>
    <!-- Intent is DACS Single-level record, plus 650 and 655 and 7xx for access. The function of the MARC record is to serve as an advertisement for the finding aid.  -->
    <xsl:template match="/">
        <!-- marc:collection -->
        <!--<collection xmlns:marc="http://www.loc.gov/MARC21/slim"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">-->
        <xsl:for-each select="//archdesc/did[1]">
            <record>
                <leader>
                    <xsl:text>00000n</xsl:text>
                    <!-- LDR/06 values based on title -->
                    <xsl:choose>
                        <xsl:when
                            test="contains(lower-case(normalize-space(unittitle[1])), 'photograph') or contains(lower-case(normalize-space(unittitle[1])), 'negative') or contains(lower-case(normalize-space(unittitle)), 'film')">
                            <xsl:text>k</xsl:text>
                        </xsl:when>
                        <xsl:when
                            test="contains(lower-case(normalize-space(unittitle[1])), 'sound') or contains(lower-case(normalize-space(unittitle[1])), 'recording')">
                            <xsl:text>i</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains(repository/@id, 'book')">
                            <xsl:text>a</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>p</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>caa2200000u  4500</xsl:text>
                </leader>
                <controlfield tag="008">
                    <!-- This is what it's supposed to look like:  <controlfield tag="008">181217i16862010xx                      d</controlfield> -->
                    <!-- positions 0-17, all LDR/06 -->
                    <xsl:value-of select="'181218i'"/>
                    <xsl:choose>
                        <xsl:when test="unitdate[1]/@normal">  <xsl:value-of select="substring-before(unitdate[1]/@normal, '/')"/></xsl:when><xsl:otherwise><xsl:text>uuuu</xsl:text></xsl:otherwise>
                    </xsl:choose>

                    <xsl:choose>
                        <xsl:when
                            test="substring-before(unitdate[1]/@normal, '/') = substring-after(unitdate[1]/@normal, '/')">
                            <xsl:text>    </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="substring-after(unitdate[1]/@normal, '/')"/>
                            <xsl:if test="not(unitdate[1]/@normal)"><xsl:text>uuuu</xsl:text></xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>xx </xsl:text>
                    <!-- positions 18-34, related to LDR/06 -->
                    <xsl:choose>
                        <xsl:when
                            test="contains(lower-case(normalize-space(unittitle[1])), 'photograph') or contains(lower-case(normalize-space(unittitle[1])), 'negative') or contains(lower-case(normalize-space(unittitle)), 'film')">
                            <xsl:text>               ||</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>                 </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- positions 35-37, language -->
                    <xsl:value-of select="langmaterial[1]/language[1]/@langcode"/>
                    <xsl:if test="not(langmaterial/language/@langcode)">
                        <xsl:value-of select="'   '"/>
                    </xsl:if>
                    <!-- positions 38-39, all LDR/06 -->
                    <xsl:text> d</xsl:text>
                </controlfield>
                <controlfield tag="001">
                    <xsl:value-of select="//eadid"/>
                </controlfield>
                <!-- arbitrary value, just something for 035 -->
                <controlfield tag="003">
                    <xsl:value-of select="'PULFA'"/>
                </controlfield>
                <datafield ind1=" " ind2=" " tag="040">
                    <subfield code="a">NjP</subfield>
                    <subfield code="b">eng</subfield>
                    <subfield code="e">dacs</subfield>
                    <subfield code="c">NjP</subfield>
                </datafield>
                <!-- language codes  -->
                <xsl:if test="count(langmaterial/language) > 1">
                    <datafield ind1="0" ind2=" " tag="041">
                        <xsl:for-each select="langmaterial/language">
                            <subfield code="a">
                                <xsl:value-of select="./@langcode"/>
                            </subfield>
                        </xsl:for-each>
                    </datafield>
                </xsl:if>
                <!-- 1xx, including repository  -->
                <xsl:for-each select="origination[1]/*[1]">
                    <xsl:variable name="cleanname" select="normalize-space(replace(., '´', ''))"/>
                    <datafield>
                        <xsl:attribute name="tag">
                            <xsl:choose>
                                <xsl:when test="local-name(.) = 'persname'">
                                    <xsl:text>100</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'corpname'">
                                    <xsl:text>110</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'famname'">
                                    <xsl:text>100</xsl:text>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:attribute name="ind1">
                            <xsl:choose>
                                <xsl:when test="local-name(.) = 'persname'">
                                    <xsl:text>1</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'corpname'">
                                    <xsl:text>2</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'famname'">
                                    <xsl:text>3</xsl:text>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:choose>
                                <xsl:when test="local-name(.) = 'persname'">
                                    <xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'corpname'">
                                    <xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'famname'">
                                    <xsl:text> </xsl:text>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                        <subfield code="a">
                            <xsl:value-of select="$cleanname"/>
                        </subfield>
                    </datafield>
                </xsl:for-each>
                <!-- title and date  -->
                <xsl:for-each select="unittitle[1]">
                    <datafield ind1="0" tag="245">
                        <xsl:attribute name="ind2">
                            <xsl:choose>
                                <xsl:when test="not(@altrender)">0</xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of
                                        select="string-length(substring-before(normalize-space(.), ' ')) + 1"
                                    />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <subfield code="a">
                            <xsl:value-of select="normalize-space(.)"/>
                            <xsl:text>, </xsl:text>
                        </subfield>
                        <xsl:for-each select="../unitdate[not(@type = 'bulk')][1]">
                            <subfield code="f">
                                <xsl:value-of select="normalize-space(../unitdate[1])"/>
                                <xsl:if test="not(../unitdate[@type = 'bulk'])">
                                    <xsl:text>.</xsl:text>
                                </xsl:if>
                            </subfield>
                        </xsl:for-each>
                        <xsl:for-each select="../unitdate[@type = 'bulk'][1]">
                            <subfield code="g">
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="normalize-space(../unitdate[1])"/>
                                <xsl:text>)</xsl:text>
                            </subfield>
                        </xsl:for-each>
                    </datafield>
                </xsl:for-each>
                <!-- extent  -->
                <datafield ind1=" " ind2=" " tag="300">
                    <subfield code="a">
                        <xsl:for-each select="physdesc/extent">
                            <xsl:if test="position() > 1">
                                <xsl:text>, </xsl:text>
                            </xsl:if>
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:for-each>
                    </subfield>
                </datafield>
                <!-- abstract, as scope and content  -->
                <xsl:for-each select="//abstract[1]">
                    <datafield ind1="2" ind2=" " tag="520">
                        <subfield code="a">
                            <xsl:value-of select="normalize-space(.)"/>
                        </subfield>
                    </datafield>
                </xsl:for-each>
                <!-- restrictions on access and use: general note to see the finding aid  -->
                <datafield ind1="1" ind2=" " tag="506">
                    <subfield code="a">
                        <xsl:text>See finding aid for note on access and use.</xsl:text>
                    </subfield>
                </datafield>
                <!-- 6xx -->
                <xsl:for-each
                    select="../controlaccess/(child::geogname | child::subject[not(@source = 'local')])">
                    <datafield>
                        <xsl:attribute name="tag">
                            <xsl:choose>
                                <xsl:when test="local-name(.) = 'geogname'">
                                    <xsl:text>651</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'subject'">
                                    <xsl:text>650</xsl:text>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:attribute name="ind1">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:text>0</xsl:text>
                        </xsl:attribute>
                        <xsl:variable name="cleanterm" select="normalize-space(replace(., '´', ''))"/>
                        <xsl:variable name="subtoken" select="tokenize($cleanterm, '--')"/>
                        <xsl:for-each select="$subtoken">
                            <xsl:if test="position() = 1">
                                <subfield code="a">
                                    <xsl:value-of select="normalize-space(.)"/>
                                </subfield>
                            </xsl:if>
                            <xsl:if test="position() > 1">
                                <subfield>
                                    <xsl:attribute name="code">
                                        <xsl:choose>
                                            <xsl:when
                                                test="matches(substring(normalize-space(.), 1, 2), '\d\d')">
                                                <xsl:text>y</xsl:text>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:text>x</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </subfield>
                            </xsl:if>
                        </xsl:for-each>
                    </datafield>
                </xsl:for-each>
                <xsl:for-each select="../controlaccess/genreform">
                    <datafield ind1=" " ind2="7" tag="655">
                        <xsl:variable name="gentoken" select="tokenize(normalize-space(.), '--')"/>
                        <xsl:for-each select="$gentoken">
                            <xsl:if test="position() = 1">
                                <subfield code="a">
                                    <xsl:value-of select="normalize-space(.)"/>
                                </subfield>
                            </xsl:if>
                            <xsl:if test="position() > 1">
                                <subfield>
                                    <xsl:attribute name="code">
                                        <xsl:choose>
                                            <xsl:when
                                                test="matches(substring(normalize-space(.), 1, 2), '\d\d')">
                                                <xsl:text>y</xsl:text>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:text>x</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </subfield>
                            </xsl:if>
                        </xsl:for-each>
                        <subfield code="2">
                            <xsl:value-of select="@source"/>
                        </subfield>
                    </datafield>
                </xsl:for-each>
                <!-- 7xx  -->
                <xsl:for-each
                    select="child::origination[1]/child::*[position() > 1] | child::origination[position() > 1]/child::* | ../child::controlaccess/(child::persname | child::corpname | child::famname)[not(contains(., '--'))]">
                    <xsl:variable name="cleanname" select="normalize-space(replace(., '´', ''))"/>
                    <datafield>
                        <xsl:attribute name="tag">
                            <xsl:choose>
                                <xsl:when test="local-name(.) = 'persname'">
                                    <xsl:text>700</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'corpname'">
                                    <xsl:text>710</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'famname'">
                                    <xsl:text>700</xsl:text>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:attribute name="ind1">
                            <xsl:choose>
                                <xsl:when test="local-name(.) = 'persname'">
                                    <xsl:text>1</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'corpname'">
                                    <xsl:text>2</xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'famname'">
                                    <xsl:text>3</xsl:text>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:choose>
                                <xsl:when test="local-name(.) = 'persname'">
                                    <xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'corpname'">
                                    <xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:when test="local-name(.) = 'famname'">
                                    <xsl:text> </xsl:text>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                        <subfield code="a">
                            <xsl:value-of select="$cleanname"/>
                        </subfield>
                    </datafield>
                </xsl:for-each>
                <!-- ARK -->
                <datafield ind1="4" ind2="2" tag="856">
                    <subfield code="z">
                        <xsl:text>Finding aid: </xsl:text>
                    </subfield>
                    <subfield code="u">
                        <xsl:value-of select="//eadid/@url"/>
                    </subfield>
                </datafield>
                <!-- holdings: location and call number -->
                <xsl:for-each select="physloc[@type = 'code']">
                    <datafield ind1="8" ind2=" " tag="852">
                        <subfield code="b">
                            <xsl:value-of select="normalize-space(.)"/>
                        </subfield>
                        <subfield code="h">
                            <xsl:value-of select="//unitid[@type = 'collection'][1]"/>
                        </subfield>
                    </datafield>
                </xsl:for-each>
            </record>
        </xsl:for-each>
        <!--</collection>-->
    </xsl:template>
</xsl:stylesheet>
