<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs" version="2.0">
    
    <xsl:output encoding="ISO-8859-1"/>
    
    <xsl:template match="/*">
        
        <xsl:processing-instruction name="xml-model">href="../../derivatives/shelley-godwin-page.rnc" type="application/relax-ng-compact-syntax"
        </xsl:processing-instruction>
        <xsl:processing-instruction name="xml-model">href="../../derivatives/shelley-godwin-page.isosch" type="application/xml"
        </xsl:processing-instruction>
        <xsl:processing-instruction name="xml-stylesheet">type="text/xsl" href="../../xsl/page-proof.xsl"
        </xsl:processing-instruction>
        
        <xsl:copy>
            <xsl:namespace name="sga">http://shelleygodwinarchive.org/ns/1.0</xsl:namespace>
            <xsl:copy-of select="@*| node()"/>
        </xsl:copy>
    </xsl:template>

    <!--<xsl:template match="tei:surface">
        <xsl:copy-of select="."/>
    </xsl:template>-->

</xsl:stylesheet>
