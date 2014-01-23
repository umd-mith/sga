<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">

    <!-- Stylesheet to switch all @resp attributes to @hand, as a result of a change in encoding policy. 
            ISO-8859-1 character encoding used to preserve unicode NCRs -->

    <xsl:output encoding="ISO-8859-1"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="//@resp">
        <xsl:attribute name="hand">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

</xsl:stylesheet>
