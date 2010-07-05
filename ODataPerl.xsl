<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:edm="http://schemas.microsoft.com/ado/2007/05/edm">

    <xsl:output method="text"/>

    <xsl:template match="/">
        <xsl:for-each select="//edm:Schema">
package <xsl:value-of select="//edm:Schema/@Namespace" />;
use Moose;
use namespace::autoclean;

            <xsl:for-each select="edm:ComplexType">
package <xsl:value-of select="//edm:Schema/@Namespace" />::<xsl:value-of select="@Name" />;
use Moose;
use namespace::autoclean;

                <xsl:for-each select="edm:Property">
has '<xsl:value-of select="@Name" />' => ( is => 'ro', isa => '<xsl:value-of select="@Type" />');
                </xsl:for-each>

1;
            </xsl:for-each>
            <xsl:for-each select="//edm:Schema//edm:EntityType">
package <xsl:value-of select="//edm:Schema/@Namespace" />::<xsl:value-of select="@Name" />;
use Moose;
use namespace::autoclean;

extends '<xsl:value-of select="//edm:Schema/@Namespace" />';
                <xsl:for-each select="edm:Property">
has '<xsl:value-of select="@Name" />' => ( is => 'ro', isa => '<xsl:value-of select="@Type" />');
                </xsl:for-each>

sub get_key {
    my $self = shift;
    return $self-><xsl:value-of select="edm:Key/edm:PropertyRef/@Name" />(); 
}

                <xsl:for-each select="edm:NavigationProperty">
sub get_<xsl:value-of select="@Name" /> {
    my $self = shift;
    return "<xsl:value-of select="@Name" />";
}
                </xsl:for-each>
    

1;
            </xsl:for-each>
       </xsl:for-each>
    </xsl:template>
</xsl:transform>
