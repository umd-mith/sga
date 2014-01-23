<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei"
    version="2.0">
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Replaces pointer with the appropriate URI for PBS (from VIAF) -->
    <xsl:template match="@resp['#pbs']">
        <xsl:attribute name="resp">http://viaf.org/viaf/95159449</xsl:attribute>
    </xsl:template>
    
</xsl:stylesheet>