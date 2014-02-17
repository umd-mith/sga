# Shelley-Godwin Archive
# Core TEI Elements for Encoding Primary Manuscripts

The encoding schema for the Shelley-Godwin Archive is adapted from the encoding model for Genetic Editions and Genetic Editing:

http://www.tei-c.org/Activities/Council/Working/tcw19.html

Genetic encoding principles allow us to encode a manuscript so that each
stage of the composition process is captured. Our encoding will allow the 
user to see not only the final diplomatic transcription (as in a print 
edition), but to also examine the development of the manuscript from one 
stage of composition to the next. Each stage, or layer, of the text can be 
isolated, extracted, and compared. Users will also be able to read a
redacted transcription that represents the author's final draft intention.
This "reading" text will omit deleted text, place added text in its
appropriate position, transpose text (when indicated in the MS), and link
text from different locations in the MS that is meant to be merged.

The encoding model below was designed to encode the *Frankenstein* notebooks.
As we begin to encode other manuscripts, we will further develop the schema
to account for formal and conceptual differences among prose, poetry, and
drama.

## 1. Zones `<zone type="main" "left_margin" "library" "pagination" "top">`

The physical manuscript page (`<surface>`) is composed of zones. The "main"
zone contains the main body of writing. The "pagination" zone contains page 
numbers supplied by the author. The "library" zone contains additional 
information, such as folio numbers, supplied by the holding library. The 
"top" zone contains chapter headings or titles. And the "left-margin" zone 
indicates that a margin has been created on the left side of the page using 
a vertical pencil line. For the *Frankenstein* manuscript, the left margin 
zone is used as either a space for additions or for paratextual notations . 
The differing characteristics of manuscript sources will determine what 
kinds of zones will be identified.

Example (c56-0005):

```xml
<zone type="library">1</zone>
<zone type="top">
  <line>Chapt. 2</line>
</zone>
<zone type="main">
  <line>Those events which materially influence our fu</line>
  ...
</zone>
```

## 2. Lines `<line>`

Each topographical line of writing in the manuscript is enclosed within the
`<line>` element.

Example (c56-0005):

```xml
<line>of directing the attention of their pupils to</line>
<line>useful knowledge, which they utterly neglect.</line>
```

## 3. Paragraphs `<milestone unit="tei:p"/>`

To indicate a paragraph break, use the `<milestone/>` element.

Example (c56-0008):

```xml
<milestone unit="tei:p"/>
  <line rend="indent1">The natural ph&#xE6;nonema that takes</line>
```

The forward slash "/" indicates that the element is empty, so it does not 
require a closing tag.

## 4. Simple Additions `<add place="superlinear" "sublinear" "intralinear" "interlinear">`

Superlinear Example (c56-0041):

```xml
<line>on by an eagerness which <add place="superlinear" hand="#pbs">perpetually</add> encreased,</line>
```

Sublinear Example (c56-0071):

```xml
<line>ing my endeavours to throw them off <add place="sublinear" hand="#pbs">with an invincible burthen.</add></line>
```

Intralinear Example (c56-0006):

```xml
<line>the wild fancies of the<add place="intralinear" hand="#pbs">se</add> authors with</line>
```

## 5. Simple Deletions `<del rend="strikethrough" "smear" "overwritten" "unmarked">`

The most common deletion type is a strikethrough. Less common forms of
deletion include ink smears, overwrites, and vertical lines. Although there 
are variations from  these fundamental deletion types, such as diagonal 
lines, wavy lines, and scribbles of various kinds, for now indicate 
deletions using only the four attributes listed. We want to avoid 
inconsistencies in the encoding model due to encoders improvising and trying 
to account for every possible variation by customizing the attribute values. 
If you run into something that can not be accurately described in the 
current encoding schema, make a note of it and consult with the project 
editors.

Strikethrough Example (c56-0014):

```xml
<line>the <del rend="strikethrough">trea</del> tree shattered in a</line>
```

Smear Example (c56-0049):

```xml
<line><space unit="chars" extent="7"/>"<del rend="smear">wal</del>And turns no more his head</line>
```

Overwritten Example (c56-0005):

```xml
<line>to fin<mod><del rend="overwritten">ed</del><add place="intralinear">d</add></mod> a <del rend="strikethrough">fo</del> volume<del rend="strikethrough">s</del> of the Works of Corne</line>
```

Because overwritten text includes both an addition and a deletion, it is 
enclosed within a `<mod>` element that links them as a single authorial 
intervention.

In cases where the strikethrough mark does not extend through the entire 
line or phrase, but the entire line or phrase is clearly meant to be 
deleted, use the value "unmarked." For example, 
`<del rend="unmarked">W</del><del rend= "strikethrough">hen I saw</del>`

## 6. Multiple Line Additions and Deletions `<addSpan/>` `<delSpan/>` `<anchor xml:id=""/>`

To encode additions and deletions that span across multiple lines, use the
`<addSpan/>` and `<delSpan/>` elements. The `<anchor/>` element marks the 
stopping point.

`<delSpan/>` Example (c56-0015):

```xml
<line><delSpan rend="vertical_line" spanTo="#c56-0015.01"/>ph&#xE6;nonema. On Elizabeth and</line>
<line>Clerval it produced a <del rend="strikethrough">di</del> very different</line>
<line>effect. They admired the beauty</line>
<line>of the storm without wishing to</line>
<line>analyze its causes. Henry said that</line>
<line>the Fairies and giants were at</line>
<line>war and Elizabeth attempted</line>
<line>a picture of it. <anchor xml:id="c56-0015.01"/></line>
```

Notice that some of the text within the passage was deleted before the
entire passage was later cancelled with a vertical line.

`<addSpan/>` Example (c56-0014):

```xml
<zone type="left_margin" corresp="#c56-0014.07">
  <addSpan spanTo="#c56-0014.08" hand="#pbs"/>
    <line>its progress</line>
    <line>with curiosity</line>
    <line>&#x26; delight</line>
  <anchor xml:id="c56-0014.08"/>
</zone>
```

The `<zone>` element in the example above includes the `@corresp` attribute
that links the marginal addition to an insertion point in the main zone of 
writing (see below).

In both the `<addSpan/>` and `<delSpan/>` elements, include the "spanTo" 
attribute to indicate the stopping point (`<anchor/>`).

## 7. Simple Modifications <mod>

The `<mod>` element is used to group several interventions into one textual revision: for example, substitutions, corrections, and overwrites. The `<mod>` element also allows us to encode the sequence of these changes. The deletion is encoded first, followed by the addition.

Example (c56-0014):

<table>
  <tr><td></td><td align="center"><em>so soon as</em></td><td></td></tr>
  <tr><td>our house</td><td>and <del>when</del> then</td><td><del>dazz</del></td></tr>
</table>

```xml
<line>our house and <mod>
                <del rend="strikethrough">when</del>
                <add place="superlinear" hand="#pbs">so soon as</add>
            </mod> the <del rend="strikethrough">dazz</del></line>
```

The `<mod>` element is also used to group together a caret (or other 
metamark) and added text for which the metamark indicates an insertion point.

Example:

<table>
  <tr><td colspan="2">blasted</td><td></td></tr>
  <tr><td><del>rent</del></td><td> stump. <del>remained</del>. When we</td></tr>
  <tr><td align="right">^</td><td></td></tr>
</table>

```xml
<line><mod>
                <del rend="strikethrough">rent</del>
                <add place="sublinear"><metamark function="insert">&#x2038;</metamark></add>
                <add place="superlinear">blasted</add>
            </mod> stump. <del rend="strikethrough">remained</del>. When we</line>
```

The caret was inserted below "rent" and indicates where the added "blasted" 
(written above the line) should be inserted.

## 8. Cross-linear Modifications `<mod spanTo="xxx"/><add next=""><del next="">`

Let's take a look at a complex modification that spans several lines. These 
are more difficult because of the nesting problems that arise when 
attempting to link together a modification that spans across the `<line>` 
element or other elements. Link cross-linear additions and deletions by 
inserting the "next" attribute within the element and linking it to an 
xml:id with the same value within the partner addition or deletion. Using 
the "next" attribute allows us to encode the following passage as one 
addition and one deletion.

Example (c56-0014):

<pre><em><add>As I stood at the door</add></em>
... <del>When it was most</del>
<em>on a sudden</em>
<del>violent,</del> ...</pre>

```xml
<line>... <mod spanTo="#c56-0014.09"/>
  <del rend="strikethrough" next="#c56-0014.10">When it was most</del>
  <add place="superlinear" hand="#pbs" next="#c56-0014.15">As I stood at the door</add></line>
<line><del rend="strikethrough" xml:id="c56-0014.10">violent</del><add place="superlinear" hand="#pbs" xml:id="c56-0014.15">on a sudden</add>
    <anchor xml:id="c56-0014.09"/>, ...</line>
```

## 9. Linking Material from Different Zones

In the *Frankenstein* rough draft, many of the pages are divided by a
vertical pencil line that creates an empty left margin within which to make
additions or add comments. To link additions from the left margin to the
text in the main draft zone, use the `@corresp` attribute. Text in the left
margin is encoded as an addition, so nest it within the `<add>` or
`<addSpan>` elements. Use `<anchor/>` to indicate the end of an `<addSpan/>`.
The `<anchor/>` element is empty and only indicates the end of an added
passage.

Example (c56-0014):

```xml
<zone type="main">
<line> . . . <anchor xml:id="c56-0014.07"/> . . . </line>
<zone/>

<zone type="left_margin" corresp="#c56-0014.07">
  <addSpan spanTo="#c56-0014.08" hand="#pbs"/>
   <line>its progress</line>
   <line>with curiosity</line>
   <line>&#x26; delight</line>
  <anchor xml:id="c56-0014.08"/>
</zone>
```

For a marginal addition of only a single line, simply place a `@corresp`
attribute in the zone element to link it to either the `<anchor/>` or
`<metamark>` element within the main zone.

Example (c57-0002):

```xml
<zone type="left_margin" corresp="#c57-0002.02">
  <line><del rend="strikethrough">
      <add hand="#pbs">various</add>
    </del></line>
</zone>
```

In the above example, the addition was later deleted, so it is nested within
the `<del>` element.

The following example is more complex (c57-0078):

```xml
<zone type="left_margin" corresp="#c57-0078.02">
<delSpan rend="vertical_line" spanTo="#c57-0078.03"/>
<addSpan spanTo="#c57-0078.04" hand="#pbs"/>
  <line>I think</line>
  <line>the journey</line>
  <line>to England</line>
  <line>ought to be</line>
  <line><hi rend="underline">Victor's</hi> propo</line>
  <line>-sal.— that he</line>
  <line>ought to go</line>
  <line>for the purpose of</line>
  <line>collecting</line>
  <line>knowledge, for</line>
  <line>the formation</line>
  <line>of a female.</line>
  <line>He ought to</line>
  <line>lead his father to</line>
  <line>this in</line>
  <line>the conversa</line>
  <line>tions—the</line>
  <line>conversation</line>
  <line><hi rend="underline">commences</hi></line>
  <line>right enough</line>
  <anchor xml:id="c57-0078.04"/>
  <anchor xml:id="c57-0078.03"/>
</zone>
```

This marginal addition, in the hand of Percy, was ultimately deleted by 
striking through the text with a vertical line. There are also several words 
that have been underlined. Use the `<hi>` (highlight) element with 
"underline" as the value for the "rend" attribute. `<hi>` can also be used 
to encode superscript text ("sup") and other variations from the normal 
appearance of the text.

The next example from c57-0013 is even more complex and includes the unholy 
alliance of cross-linear additions and deletions, super- and sublinear 
additions, and text from the left margin that is meant to be inserted into 
the main body. Furthermore, there are hand shifts between MWS and PBS and 
instances where MWS overwrites or changes in ink what PBS had written in 
pencil. To avoid madness, simply indicate the hand as it is given in the 
transcription file. The reviewer will sort out the details later.

If the text showed only a multiple-line deletion from "my own hard nerves" 
to "young ma" then we could simply encode the deletion using `<delSpan/>`. 
But since there are additions meant to replace that deleted text, we need to 
use the `<mod spanTo/>` element and include the "next" attribute in the 
`<add>` and `<del>` elements; otherwise, those additions would be subsumed 
as part of the `<delSpan/>`. So each addition and deletion needs to be 
encoded separately for each line and then linked together with the "next" 
attribute. We also need to indicate where the additions in the left margin 
should be placed in the main zone. Create an `<anchor/>` in the main zone, 
assign it an xml:id, and then link it to the left-margin zone with the
`@corresp` attribute; i.e., the left-margin zone corresponds to an anchor or 
metamark that signifies an insertion point in the main zone of text.

The transcription reads as follows (with PBS's handwriting in italics):

<table>
  <tr>
    <td></td>
    <td width="5%"></td>
    <td style="font-size: smaller; padding-left: 8em;">
      <em>sensations of a peculiar &amp; overpowering</em>
    </td>
  </tr>
  <tr>
    <td align="right" style="font-size: smaller;">were a</td>
    <td></td>
    <td>love that I felt <del>my own hard nerves</del></td>
  </tr>
  <tr>
    <td style="font-size: smaller;">nature they</td>
    <td></td>
    <td>mixture <em>of pain &amp; pleasure; such <del>as</del> as
      I had never experienced</em></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td><del>move and I was obliged to withdraw from</del></td>
  </tr>
  <tr>
    <td style="font-size: smaller;">withdraw</td>
    <td></td>
    <td style="font-size: smaller;">
      <em>either from the hunger or cold, <del>orfrom</del> or warmth or
      food&nbsp;&nbsp;and I</em>
    </td>
  </tr>
  <tr>
    <td style="font-size: smaller;">from my station</td>
    <td></td>
    <td><del>my the hole. Presently the young ma</del></td>
  </tr>
  <tr>
    <td style="font-size: smaller"><em>unable to</em></td>
  </tr>
  <tr>
    <td style="font-size: smaller"><em>bear those</em></td>
  </tr>
  <tr>
    <td style="font-size: smaller"><em><del>emotions</del></em></td>
  </tr>
  <tr>
    <td style="font-size: smaller"><em>emotions</em></td>
  </tr>
</table>

The encoded transcription reads:

```xml
<zone type="main">
... 
<line>love that I felt <mod spanTo="#c57-0013.01"/>
  <del rend="strikethrough" next="#c57-0013.02">my own hard nerves</del>
  <add hand="#pbs" place="superlinear" next="#c57-0013.03">sensations of a peculiar &#x0026; overpowering</add></line>
<line><del rend="strikethrough" xml:id="c57-0013.02" next="#c57-0013.04">move and I was
  obliged to withdraw from</del><anchor xml:id="#c57-0013.05"/>
  <add place="superlinear" xml:id="c57-0013.09" hand="#pbs" next="#c57-0013.06">mixture of pain &#x0026; pleasure; such <del rend="strikethrough">as</del> as
    I had never experienced</add></line>
<line><del rend="strikethrough" xml:id="c57-0013.04">my the hole.  Presently the young
ma</del><add hand="#pbs" place="superlinear" xml:id="c57-0013.06"> either from <del rend="strikethrough">the</del> hunger or cold, <del rend="strikethrough">orfrom</del> or warmth or food<space unit="chars" extent="3"/> and I</add>
  <anchor xml:id="c57-0013.07"/><anchor xml:id="c57-0013.01"/></line>
...
</zone>

<zone type="left_margin" corresp="#c57-0013.05">
       <line><add next="#c57-0013.09">nature they <add place="superlinear">were  a</add></add></line>
</zone>

<zone type="left_margin" corresp="#c57-0013.07">
<addSpan spanTo="#c57-0013.08"/>
  <line>withdrew</line>
  <line>from my station</line>
  <line><handShift new="#pbs"/>unable to</line>
  <line>bear these</line>
  <line><del rend="strikethrough">emotio</del>ns</line>
  <line><handShift new="#mws"/>emotions</line>
<anchor xml:id="c57-0013.08"/>
</zone>
```

## 10. Shifts in Hands

```xml
<add hand="#pbs" "#comp">
<handShift new="#pbs" "#comp" "#mws"/>
```

To indicate an addition in a hand other than that of the primary author, use the "hand" attribute within the `<add>` element.

Example:

<table>
  <tr><td></td><td align="center" style="font-size: smaller;"><em>which</em></td></tr>
  <tr><td>string</td><td align="center"><del>and</del></td></tr>
</table>

```xml
<line>string <mod><del rend="strikethrough">and</del><add place="superlinear" hand="#pbs">which</add></mod></line>
```

To indicate a shift in hands, use the `<handShift/>` element. For example,
during the transcription of the fair-copy manuscript of *Frankenstein*,
Percy takes over for Mary for an extended number of pages. Since this is not
an addition, we mark the beginning of Percy's hand with 
`<handShift new="#pbs"/>`. The backslash indicates that the element is empty 
and that the shift in hand continues until another shift in hand takes place.

## 11. Uncertain Readings `<unclear unit="char" extent="">`

Text that is illegible is enclosed within the `<unclear>` element. If the 
text is partially recognizable, indicate it as follows:

```xml
<line>During her confinement <unclear>mady</unclear> many</line>
```

If the text is obscured by ink blots, foxing, or is completely illegible, 
encode it using an empty `<unclear/>` tag and indicate the approximate 
length ("extent") of the uncertain reading. "chars" stands for "characters".

```xml
<line>During her confinement <unclear unit="chars" extent="4"/> many<line>
```

## 12. Encoding Spaces and Indentations `<space unit="" extent=""> <line rend="">`

To encode significant spaces between passages or words, use the `<space>`
element and indicate the extent of the space.

```xml
<line>acquired <space unit="chars" extent="20"/> and</line>
```

Do not encode spaces unless there is a noticeable gap that extends beyond 
the normal variation of spaces within a handwritten manuscript.

To encode indentations such as the beginning of a new paragraph or poetry 
lines, use the `@rend` attribute within the `<line>` element. The values for 
the `@rend` attribute include 5 levels of indentation in addition to
"center," "left," and "right."

## 13. Damage to the Manuscript `<damage>` `<damageSpan/>`

If text is illegible or missing from manuscript because of damage, such as 
being torn or cut away, use the `<damage>` element. The reviewer will add 
more details to the encoding.

## 14. Paratextual Notations and Additions `<milestone unit="tei:note"/> <metamark>`

For paratextual notations such as carets, brackets, and "X"s that indicate 
insertion points for added material, enclose them within the `<metamark>` 
element.

For notes or instructions added by either the author or compositor, use the 
`<note>` element. For example, in the fair-copy draft for *Frankenstein*,
the compositor writes his initials and indicates where he either ends or
begins typesetting:

```xml
<line><milestone unit="tei:note" spanTo="#xxx"><add hand="#comp">F. W.<metamark>/</metamark><anchor xml:id="xxx">My courage . . .</line>
```

## 15. Restoring Deleted Text and Retracing Text

```xml
<restore type="smear_strikethrough" "stetdots" "underline">

<retrace cause="fix" "clarify" hand="">
```

To encode instances where deleted text has been restored by using stet dots, 
smearing the cancellation line, or underlining, use the `<restore>` element.

Restore Example (c56-0051):

```xml
<line>"<restore type="smear_strikethrough"><del rend="strikethrough">a year</del></restore>
  <del rend="smear"><add place="superlinear">y<hi rend="sup">r</hi>.</add></del>
     with</line>
```

To indicate where text has been retraced for some reason, use the `<retrace>`
element and indicate a change in hands if applicable. The value "fix" means 
that the purpose of the rewrite is to make the text permanent. In the 
following example, PBS rewrites text that MWS originally wrote to indicate 
that he agrees with the addition.

Retrace to Fix Example (c56-0004):

```xml
<line>of pleasure to <mod>
    <del rend="strikethrough">Thonon</del>
    <retrace cause="fix" hand="#pbs">
      <add place="superlinear">the baths near</add>
    </retrace>
    <add place="superlinear" hand="#pbs">Thonon.</add>
  </mod>
  <del rend="strikethrough">and were confined there</del></line>
```

A more common occurrence is when text is rewritten for the purpose of 
clarifying it. The value "clarify" is used in these instances.

Retrace to Clarify Example (c56-0053):

```xml
<line>joy and ran down to Henr<retrace cause="clarify" hand="#pbs">y</retrace>.</line>
```

Here, PBS does not add the "y"; he writes over MWS's misformed or unclear 
"y" to clarify it.

## 17. Sketches and Doodles `<figure>` `<figDesc>`

Percy often likes to sketch trees, clouds, and other figures on the page 
apart from the textual draft. To encode these sketches and doodles, create a 
separate zone and nest the description (`<figDesc>`) of the sketch within 
the `<figure>` element.

Example (c57-0005):

```xml
<zone type="left_margin">
  <add hand="#pbs"><figure>
    <figDesc>PBS sketch of tree</figDesc>
  </figure></add>
</zone>
```

## 18. Transpositions and Alternative Readings `<transpose>` `<alt>`

1. `<transpose>` example from c57-0178

    ```xml
    <line>destroyed my friend &#x2013;
      <milestone unit="tei:seg" xml:id="c57-0178.02" spanTo="#c57-0179.03"/>beings who <mod><del rend="strikethrough">had</del>
        <anchor xml:id="#c57-0179.01"/></mod></line>
    <line>sensations &#x2013; happiness &amp; wisdom<anchor xml:id="c57-0179.03"/>
          <milestone unit="tei:seg" xml:id="c57-0179.04" spanTo="#c57-0179.05"/>he</line>
    <line>devoted to destruction<anchor xml:id="c57-0179.05"/>
          <listTranspose>
            <transpose>
          <ptr target="#c57-0179.04"/>
          <ptr target="#c57-0179.02"/>
            </transpose>
          </listTranspose> Nor do I know</line>
    ```

2. `<alt/>` example from c57-0002

    ```xml
    <line><seg type="alternative" xml:id="c57.0002.02">perceive</seg><add place="superlinear" hand="#pbs" type="alternative" xml:id="c57-0002.03">recieve</add> shade. This was the forest near Ingolstadt,</line>
    <alt mode="excl" target="#c57-0002.02 #c57-0002.03" weights="0 1"/>
    ```

   Use `<alt/>` to encode cases where two or more alternative words or 
   phrases are written but no decision was indicated as to which word or 
   phrase to use.

## 19. Special Character Entities (hexadecimal values)

Caret (^): \&#x2038;

Ampersand (&amp;): \&#x26;

Em-dash (&mdash;): \&#x2014;

En-dash (&ndash;): \&#x2013;

&aelig; dipthong: \&#xE6;

&AElig; dipthong: \&#xC6;

circumflex e (&ecirc;): \&#xEA;

### Encoding Poetry: *Prometheus Unbound*

1. Use the `<milestone/>` element to indicate speaker designations, stage 
   directions, acts and scenes.

   Enclose units specific to drama within the milestone element. The poetry 
   is encoded using the same elements designed for Frankenstein. Our goal is 
   to 1) encode the basic structure of the manuscript: zones, additions,
   deletions, substitutions, etc.; 2) account for speakers, stage 
   directions, acts and scenes; 3) the final stage will be to add linking 
   elements to indicate the correct order of fragments (the text of PU is 
   scattered in different sections of the MS) and to encode line groups such 
   as stanzas and sections.

   We will encode stage 3 after the first two stages have been completed.

   Example from e1-0005:

    ```xml
    <milestone unit="tei:act" spanTo="#e1-0005.01"/><line>Act 4<anchor xml:id="e1-0005.01"/>
    <metamark function="sequence">1</metamark></line>

    <milestone unit="tei:stage" spanTo="#e1-0005.03"/>
    <milestone unit="tei:p" spanTo="#e1-0005.04"/>

    <line>Scene <add place="superlinear">part of</add> a <del rend="strikethrough">beautiful</del> forest near the cave</line>
    <line>of Prometheus&#x2014; Panthea &#x26; Ione <del rend="strikethrough">are</del> are</line>
    <line><mod spanTo="#e1-0005.05"/><del rend="strikethrough">sitting beside a stream</del></line>
    <line>sleeping&#x2014; <del rend="strikethrough">dreaming&#x2014;<anchor xml:id="e1-0005.05"/> they awaken gradually</line>
      <line>during the first song.</line>
    <anchor xml:id="e1-0005.03"/><anchor xml:id="e1-0005.04"/>

    <milestone unit="tei:speaker" spanTo="#e1-0005.06"/>
    <line>Voice of unseen Spirits</line>
    <anchor xml:id="e1-0005.06"/>
    <line>The pale Stars are gone,&#x2014;</line>
    <line>For the Sun thier swift Shepherd</line>
    <line>To their folds them compelling</line>
    <line>In the depths of the Dawn</line>
    ```

2. Use the `<milestone unit="tei:l" spanTo="xxx"/>` element to link 
   topographical lines into a poetic line.

   Often, a poetic line is divided into two topographical lines when there 
   is not enough room on the MS page to accommodate the full line. For 
   example, in e1-0027:

  ```xml
  <milestone unit="tei:l" spanTo="#e1-0027.02"/><line>As the Sun rules, even with a tyrants</line>
  <line rend="right">gaze</line><anchor xml:id="e1-0027.02"/>
  <line>The unquiet Republic of the maze</line>
  <milestone unit="tei:l"  spanTo="#e1-0027.03"/><line>Of Planets, struggling fierce towards Heavens</line>
  <line rend="right">free wild<add place="superlinear">er</add>ness.</line>
  <anchor xml:id="e1-0027.03"/>
  ```

3. Indentations for poetic lines or the beginning of a new paragraph are
   encoded by using the `@rend` attribute within the `<line>` element. The 
   possible values for the rend attribute are: `center`, `right`, `left`, 
   `indent1`, `indent2`, `indent3`, `indent4`, and `indent5`.

   Example from e1-0005:

  ```xml
  <milestone unit="tei:speaker" spanTo="#e1-0005.06"/>
  <line rend="center">Voice of unseen Spirits</line>
  <anchor xml:id="e1-0005.06"/>
  <line rend="indent1">The pale Stars are gone,&#x2014;</line>
  <line rend="indent1">For the Sun thier swift Shepherd</line>
  <line rend="indent1">To their folds them compelling</line>
  <line rend="indent1">In the depths of the Dawn</line>
  <line>Hastes, in meteor-eclipsing array, &#x26; they flee</line>
  ```