<?xml version="1.0"?>
<xsl:stylesheet version='1.0' xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" indent="no" encoding="US-ASCII"/>

<xsl:template match="/">
	<xsl:for-each select="job-type-report/histogram/entry">
		<xsl:number value="position()"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select=".//*[name = 'single']/single-value"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select=".//*[name = 'multiple']/single-value"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select=".//*[name = 'condor']/single-value"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select=".//*[name = 'mpi']/single-value"/>
		<xsl:text>
</xsl:text>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
