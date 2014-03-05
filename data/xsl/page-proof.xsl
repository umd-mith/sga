<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="xs tei" version="2.0">

  <xsl:output method="xml" doctype-public="-//W3C//DTD HTML 4.01//EN"
    doctype-system="http://www.w3.org/TR/html4/strict.dtd" indent="yes"/>

  <xsl:strip-space elements="*"/>

  <xsl:variable name="lines_in_margin" select="count(//tei:zone[@type='left_margin']/tei:line)"/>

  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <title>
          <xsl:text>Page proof: </xsl:text>
          <xsl:value-of select="tei:surface/@xml:id"/>
        </title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <meta name="description"
          content="HTML rendering of a page from the Shelley-Godwin Archive project—for proofreading purposes only"/>
        <meta name="author" content="Shelley-Godwin Archive"/>

        <!-- Le styles -->
        <link href="../../derivatives/assets/css/bootstrap.css" rel="stylesheet"/>
        <style type="text/css">
          body{
              padding-top:60px;
              padding-bottom:40px;
          }
          .sidebar-nav{
              padding:9px 0;
          }
          .del {
              text-decoration: line-through;
          }
        </style>
        <link href="../../derivatives/assets/css/bootstrap-responsive.css" rel="stylesheet"/>

        <!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
        <!--[if lt IE 9]>
      <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->

        <!-- Le fav and touch icons -->
        <link href="http://fonts.googleapis.com/css?family=Antic+Slab" rel="stylesheet"
          type="text/css"/>
        <link rel="apple-touch-icon-precomposed" sizes="114x114"
          href="../assets/ico/apple-touch-icon-114-precomposed.png"/>
        <link rel="apple-touch-icon-precomposed" sizes="72x72"
          href="../assets/ico/apple-touch-icon-72-precomposed.png"/>
        <link rel="apple-touch-icon-precomposed"
          href="../assets/ico/apple-touch-icon-57-precomposed.png"/>
      </head>
      <body>

        <div class="navbar navbar-fixed-top">
          <div class="navbar-inner">
            <div class="container">
              <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                <span class="icon-bar"/>
                <span class="icon-bar"/>
                <span class="icon-bar"/>
              </a>
              <a class="brand" href="#">Shelley-Godwin Archive</a>
              <div class="nav-collapse">
                <ul class="nav">
                  <li>
                    <a href="http://umd-mith.github.com/sg-data/docs/">Docs</a>
                  </li>
                  <li>
                    <a href="https://github.com/umd-mith/sg-data">Github</a>
                  </li>
                  <li>
                    <a href="mailto:mith@umd.edu">Contact</a>
                  </li>
                </ul>
              </div>
              <!--/.nav-collapse -->
            </div>
          </div>
        </div>

        <div class="container-fluid">
          <div class="row-fluid">
            <div class="span5">
              <div class="sidebar-nav">
                <img src="http://sga.mith.org/images/derivatives/ox/{tei:surface/@xml:id}.jpg"
                  alt="placeholder" style="max-width:100%"/>
              </div>
              <!--/.well -->
            </div>
            <!--/span-->
            <div class="span7">
              <div class="row-fluid">
                <div class="span7">
                  <h3>Page Proof: <xsl:value-of select="tei:surface/@xml:id"/></h3>
                  <p>Generated at <xsl:value-of select="current-dateTime()"/></p>
                </div>
                <!--/span-->
                <div class="span7">
                  <!-- need to work through lines. every time a marginal insertion comes up, create a row-fluid split 3:9 -->
                  <xsl:apply-templates/>
                  <!--<div class="row-fluid">                   
                    <div class="span3"><p>This is a placeholder for marginal notes</p></div>
                  <div class="span9"><xsl:apply-templates/></div>
                  </div><!-\-/row-\->-->
                </div>
                <!--/span-->
              </div>
              <!--/row-->
            </div>
            <!--/span-->
          </div>
          <!--/row-->

          <hr/>

          <footer>
            <p>Shelley-Godwin Archive: For Internal Use Only</p>
          </footer>

        </div>
        <!--/.fluid-container-->
      </body>
    </html>
  </xsl:template>

  <xsl:template match="tei:zone[@type='pagination']">
    <div class="row-fluid">
      <div class="span11">&#xa0;</div>
      <div class="span1">
        <xsl:value-of select="."/>
      </div>
      <!-- not dealing with recto/verso yet -->
    </div>
  </xsl:template>

  <xsl:template match="tei:zone[@type='library']">
    <div class="row-fluid">
      <div class="span11">&#xa0;</div>
      <div class="span1">
        <xsl:value-of select="."/>
      </div>
      <!-- not dealing with recto/verso yet -->
    </div>
  </xsl:template>

  <xsl:template match="tei:zone[@type='top']">
    <div class="row-fluid">
      <div class="span4">&#xa0;</div>
      <div class="span8">
        <xsl:value-of select="."/>
      </div>
    </div>
  </xsl:template>

  <!-- Handle paragraph breaks in the outer for-each group, placement of marginal additions handled in the inner for-each-group -->
  <xsl:template match="tei:zone[@type='main']">    
    <xsl:for-each-group select="child::*" group-ending-with="tei:milestone[@unit='tei:p']">

      <xsl:for-each-group select="current-group()" group-adjacent="not(descendant::tei:ptr)">
        <!-- lines with no marginal additions -->
        <xsl:if test="not(descendant::tei:ptr)">
          <div class="row-fluid">
            <div class="span4">&#xa0;</div>
            <div class="span8">
                <span><xsl:apply-templates select="current-group()[1]"/></span>
              <span>
                <xsl:for-each select="subsequence(current-group(), 2)">
                  <xsl:apply-templates/>
                  <br/>
                </xsl:for-each>
              </span>
            </div>
          </div>
        </xsl:if>

        <!-- lines with marginal additions -->
        <xsl:if test="descendant::tei:ptr">
          <div class="row-fluid">
            <!--<div class="span4" style="margin-bottom: -{$lines_in_margin - 0.65}em">--> <!-- Styling hack here to compensate for multi-line marginal additions -->
              <div class="span4"><xsl:call-template name="process_margin"/></div>             
            <!--</div>-->
            <div class="span8">
              <span>
                <xsl:for-each select="current-group()">
                  <xsl:apply-templates/>
                  <br/>
                </xsl:for-each>
              </span>
            </div>
            <!-- The line that has a marginal addition next to it -->
          </div>
        </xsl:if>
      </xsl:for-each-group>
    </xsl:for-each-group>
  </xsl:template>

<!-- FIXME: If more than one ptr in a line, need to process all of them -->
<xsl:template name="process_margin">
  <xsl:variable name="target">
    <xsl:value-of select="substring-after(descendant::tei:ptr/@target, '#')"/>
  </xsl:variable>
  <span class="left_margin"><xsl:apply-templates select="//node()[@xml:id=$target] | //node()[@xml:id=$target]/following-sibling::tei:line"/></span>
</xsl:template>

  <xsl:template name="lb" match="tei:line">
    <xsl:apply-templates/>
    <br/>
  </xsl:template>

  <xsl:template match="tei:del[@rend='strikethrough']">
    <span class="del">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xsl:template match="tei:add">
    <xsl:choose>
      <xsl:when test="@place='superlinear'">
        <sup>
          <xsl:apply-templates/>
        </sup>
      </xsl:when>
      <xsl:when test="@place='sublinear'">
        <sub>
          <xsl:apply-templates/>
        </sub>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="tei:unclear">
    <xsl:text>&#xa0;</xsl:text>
  </xsl:template>

  <xsl:template match="tei:zone[@type='left_margin']"/>

</xsl:stylesheet>
