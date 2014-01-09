# Shared Canvas Data Model

This document describes the Shared Canvas data model as augmented and used
by the Shelley-Godwin Archive. We include guidance where the data model as
used does not conform to the current Shared Canvas data model, explaining
how our use of the data model may change in the future to bring us into
compliance with the most recent Shared Canvas data model.

Because we are using the evolving 
[Shared Canvas data model specification document](http://www.shared-canvas.org/datamodel/spec/)
and 
[IIIF Metadata API](http://www.shared-canvas.org/datamodel/iiif/metadata-api.html)
as models for this work, it is licensed under a 
[Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-nc-sa/3.0/).

The JSON-LD examples are shown using [CoffeeScript](http://coffeescript.org/)
syntax and the context outlined in the Introduction.

## Introduction

As much as possible, we produced the primary canvas sequence, ranges, and
canvas metadata from information in the TEI files. While the current
manifests are published as single files containing all of the needed
annotations, the Shared Canvas data model does allow publication of separate
files containing information on sequences, ranges, canvases, etc. 

We are in the process of moving from RDF/JSON to JSON-LD. As part of this
move, we will be composing the manifest out of a number of files to encourage
resource reuse. This document describes the data model as it was used in the
RDF/JSON manifests published at the end of October, 2013, and the data model
to which we are moving as we transition from RDF/JSON to JSON-LD.

For now, we assume that all image annotations will map the full image onto
the full canvas. Some provisions are made in the viewer code for images
mapping to part of the canvas, but we have not tested this with the
manifests we are producing.

### Document Structure

This document is composed of four primary sections after this introduction:

* "Canvas Model" discusses how we represent pages and page sections,
* "Annotations" discusses how we map content onto the canvases,
* "Ordering Model" discusses how we provide sequencing and other ordering 
  information for content, and
* "Discovery Model" discusses how we tie everything together.

Each primary section consists of sub-sections for each concept or RDF class 
used in the data model. For each concept or RDF class, we provide two
sections on the data model details:

* "RDF" describes the data model for October, 2013, and
* "JSON-LD" describes the target data model for 2014.

The "RDF" parts use the [Turtle](http://www.w3.org/TR/turtle/) RDF format
and the namespaces described below. The JSON-LD examples are shown using
[CoffeeScript](http://coffeescript.org/) syntax and the context below.

### URIs and URLs

When composing URIs for manifests and manifest components, the URI should not
end in a file extension (e.g., `.json`) while the URL from which the
resource is fetched should.

When the URL does not match the URI of the requested object, then the
returned serialization MUST have a triple of the following form:

```turtle
<URL> ore:describes <URI>
```

```json
{
  id: "URL"
  describes: "URI"
}
```

Except for the `ore:describes` link between the URI and the URL, all of the
data associated with the resource should use the URI and not the URL.

In resources that reference the URI but do not contain any of the triples
for which the URI is the subject, there should be a triple of the following
form:

```turtle
<URI> ore:describedBy <URL>
```

```json
{
  id: "URI"
  describedBy: "URL"
}
```

The Shared Canvas viewer will know to retrieve the resource at URL in order
to find all of the information associated with URI.

When a URI/URL is constructed, path components should not start with a
number since XML element names can not start with a number. Generally,
ensuring that each path component (after any namespace prefix) is a valid
XML element name allows the annotations and other relationships to be
serialized as RDF/XML. The Open Annotation community prefers JSON-LD, but
RDF/XML is a valid serialization of RDF data models.

### Namespaces

These namespaces are used in the October, 2013, manifests.

| Prefix  | Namespace                          | Description                 |
| ------- | ---------------------------------- | --------------------------- |
| sc      | http://www.shared-canvas.org/ns/   | Shared Canvas Ontology      |
| sga     | http://www.shelleygodwinarchive.org/ns1# | Shelley-Godwin Archive ontology |
| cnt     | http://www.w3.org/2011/content#    | Representing Content in RDF |
| dc      | http://purl.org/dc/elements/1.1/   | Dublin Core Elements        |
| dcterms | http://purl.org/dc/terms/          | Dublin Core Terms           |
| dctypes | http://purl.org/dc/dcmitype/       | Dublin Core types           |
| exif    | http://www.w3.org/2003/12/exif/ns# | Exif vocabulary             |
| oa      | http://www.w3.org/ns/openannotation/core/ | The Open Annotation model   |
| oax     | http://www.w3.org/ns/openannotation/extension/ | Extensions to the Open Annotation model |
| ore     | http://www.openarchives.org/ore/terms/ | The Open Archives Object Re-Use and Exchange vocabulary |
| rdf     | http://www.w3.org/1999/02/22-rdf-syntax-ns# | RDF Vocabulary     |
| rdfs    | http://www.w3.org/2000/01/rdf-schema# | RDF Schema Vocabulary    |
| xmls    | http://www.w3.org/2001/XMLSchema# | XML Schema Vocabulary |


### JSON-LD Context

The JSON-LD context is based on the 
[Shared Canvas JSON-LD context](http://www.shared-canvas.org/ns/context.json)
and additional contextual material for the Archive's ontology. Some
namespaces have changed from the October, 2013, list. For example, the Open
Annotation data model dropped its extension namespace.

```coffee
"@context":
  "@base": "http://shelleygodwinarchive.org/data/sc/"

  sc:      "http://www.shared-canvas.org/ns/"
  sga:     "http://shelleygodwinarchive.org/ns/1#"
  ore:     "http://www.openarchives.org/ore/terms/"
  exif:    "http://www.w3.org/2003/12/exif/ns#"
  iiif:    "http://library.stanford.edu/iiif/image-api/ns/"
  oa:      "http://www.w3.org/ns/oa#"
  cnt:     "http://www.w3.org/2011/content#"
  dc:      "http://purl.org/dc/elements/1.1/"
  dcterms: "http://purl.org/dc/terms/"
  dctypes: "http://purl.org/dc/dcmitype/"
  foaf:    "http://xmlns.com/foaf/0.1/"
  rdf:     "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  rdfs:    "http://www.w3.org/2000/01/rdf-schema#"
  skos:    "http://www.w3.org/2004/02/skos/core#"
  xsd:     "http://www.w3.org/2001/XMLSchema#"

  a    : "@type"
  id   : "@id"
  holds: "@container"

  license:
    a   : "@id"
    id  : "dcterms:license"
  service:
    a   : "@id"
    id  : "sc:hasRelatedService"
  seeAlso:
    a   : "@id"
    id  : "sc:hasRelatedDescription"
  within:
    a   : "@id"
    id  : "dcterms:isPartOf"
  profile:
    a   : "@id"
    id  : "dcterms:conformsTo"
  sequences:
    a    : "@id"
    id   : "sc:hasSequences"
    holds: "@list"
  canvases:
    a    : "@id"
    id   : "sc:hasCanvases"
    holds: "@list"
  resources:
    a    : "@id"
    id   : "sc:hasAnnotations"
    holds: "@list"
  images:
    a    : "@id"
    id   : "sc:hasImageAnnotations"
    holds: "@list"
  otherContent:
    a    : "@id"
    id   : "sc:hasLists"
    holds: "@list"
  structures:
    a    : "@id"
    id   : "sc:hasRanges"
    holds: "@list"
  metadata:
    a    : "@id"
    id   : "sc:metadataLabels"
    holds: "@list"

  description: "dc:description"
  attribution: "sc:attributionLabel"

  height:
    a    : "xsd:integer"
    id   : "exif:height"
  width:
    a    : "xsd:integer"
    id   : "exif:width"

  tile_height:
    a    : "xsd:integer"
    id   : "iiif:tileHeight"
  tile_width:
    a    : "xsd:integer"
    id   : "iiif:tileWidth"
  scale_factors:
    id   : "iiif:scaleFactor"
    holds: "@list"
  formats:
    id   : "iiif:formats"
    holds: "@list"
  qualities:
    id   : "iiif:qualities"
    holds: "@list"
  motivation:
    a    : "@id"
    id   : "oa:motivatedBy"
  resource:
    a    : "@id"
    id   : "oa:hasBody"
  on:
    a    : "@id"
    id   : "oa:hasTarget"
  full:
    a    : "@id"
    id   : "oa:hasSource"
  selector:
    a    : "@id"
    id   : "oa:hasSelector"
  stylesheet:
    a    : "@id"
    id   : "oa:styledBy"
  hasState:
    a    : "@id"
    id   : "oa:hasState"
  hasScope:
    a    : "@id"
    id   : "oa:hasScope"
  annotatedBy:
    a    : "@id"
    id   : "oa:annotatedBy"
  serializedBy:
    a    : "@id"
    id   : "oa:serializedBy"
  equivalentTo:
    a    : "@id"
    id   : "oa:equivalentTo"
  cachedSource:
    a    : "@id"
    id   : "oa:cachedSource"
  default:
    a    : "@id"
    id   : "oa:default"
  item:
    a    : "@id"
    id   : "oa:item"
  first:
    a    : "@id"
    id   : "rdf:first"
  rest:
    a    : "@id"
    id   : "rdf:rest"
    holds: "@list"
  hasStyle:
    a    : "@id"
    id   : "oa:hasStyle"
  styledBy:
    a    : "@id"
    id   : "oa:styledBy"
  describes:
    a    : "@id"
    id   : "ore:describes"
  describedBy:
    a    : "@id"
    id   : "ore:describedBy"

  style           : "oa:styleClass"
  viewingDirection: "sc:viewingDirection"
  viewingHint     : "sc:viewingHint"

  chars:        "cnt:chars"
  encoding:     "cnt:characterEncoding"
  bytes:        "cnt:bytes"
  format:       "dc:format"
  language:     "dc:language"
  annotatedAt:  "oa:annotatedAt"
  serializedAt: "oa:serializedAt"
  when:         "oa:when"
  value:        "rdf:value"
  start:        "oa:start"
  end:          "oa:end"
  exact:        "oa:exact"
  prefix:       "oa:prefix"
  suffix:       "oa:suffix"
  label:        "rdfs:label"
  name:         "foaf:name"
  mbox:         "foaf:mbox"

  title:     "dc:title"

  agent:     "sc:agentLabel"
  hand:      "sga:handleLabel"
  state:     "sga:stateLabel"
  shelfmark: "sga:shelfmarkLabel"
```

### Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119.

### Examples

Examples used throughout the document will be conveyed as both a diagram and
in the JSON-LD format, and may not represent specific use cases with real
resources. The JSON-LD examples do not provide context declarations, and
should be considered to follow the Namespaces and JSON-LD Context tables
above.

## Canvas Model

### Canvas

URL pattern: http://shelleygodwinarchive.org/data/canvases/{name}.json

Canvases aren't annotations, so they are simply a bag of information about
the surface we're annotating. Canvases may be referenced by multiple
manifests, so they are not considered a part of any particular manifest.

The canvas resource can have pointers to any lists of annotations it knows
about that result in content rendered on the canvas, but these are not
necessary. The viewer we're writing doesn't use these links at the moment.

The recommendation in the spec is that multiple labels should be 
translations. The viewer should then select the appropriate one.

The Shelley-Godwin Archive does not provide multiple translations of the
label. All labels are assumed to be in English or otherwise written using
UTF-8 in the primary language appropriate for the scholarly community
associated with the canvas.

#### Model

The Shared Canvas model uses:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| sc:Canvas       |         | Class     | The Class for a Canvas, which is the digital surrogate for a physical page within the model |
| exif:height     | height  | Property  | The height of the Canvas in no particular units. The height is given only to form part of the aspect ratio for the Canvas, along with the width. Each Canvas MUST have exactly one height. |
| exif:width      | width   | Property  | The width of the Canvas, in no particular units. Along with the height, this forms the aspect ratio of the Canvas. Each Canvas MUST have exactly one width. |
| rdfs:label      | label   | Property  | The human readable label intended to be displayed to a user when viewing the Canvas. Each Canvas MUST have at least one label. Multiple labels MAY be expressed in different languages and the rendering system should select an appropriate one. |
| sc:hasAnnotations | resources | Relationship | The relationship between a Canvas and a list of Annotations that target it or part of it. Each Canvas MAY have one or more lists of related annotations. |

The Shelley-Godwin Archive augments this model with:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| dc:title        | title  | Property  | The human readable label intended to convey the primary work with which this canvas is associated. In the Archive, this property overrides the equivalent property on the Manifest when viewing a particular canvas. |
| sc:agentLabel  | agent | Property  | The human readable label intended to convey the primary author(s) of the work represented by the content annotated onto this canvas. In the Archive, this property overrides the equivalent property on the Manifest when viewing a particular canvas. |
| sga:handLabel   | hand  | Property | The human readable label intended to convey the predominant hand in which the content represented by the canvas was written. In the Archive, this property overrides the equivalent property on the Manifest when viewing a particular canvas. |
| sga:stateLabel  | state   | Property | A label indicating the completeness and/or trustworthiness of the transcription and metadata associated with the canvas. In the Archive, this property overrides the equivalent property on the Manifest when viewing a particular canvas. |
| sc:attributionLabel | attribution | Property | A human readable label intended to convey the primary institution holding the physical object represented by the canvas. In the Archive, this property overrides the equivalent property on the Manifest when viewing a particular canvas. |
| sga:shelfmarkLabel | shelfmark  | Property | A human readable label intended to convey the identification of the physical aggregation containing the object represented by this canvas within the primary institution. In the Archive, this property overrides the equivalent property on the Manifest when viewing a particular canvas. |

#### RDF

```turtle
_:canvas1 a sc:Canvas ;
  exif:width "..." ;
  exif:height "..." ;
  rdfs:label "..." .
```

#### JSON-LD

```coffee
{
  id    : "_:canvas1"
  a     : "sc:Canvas"
  width : "..."
  height: "..."
  label : "..."
  resources: [ 
    # annotation lists
  ]
}
```

### Zones

A zone is an area of a canvas that can be the target of annotations,
including other zones. A zone has many of the same properties as a canvas
since it plays the role of one for annotations targeting them.

The easiest way to manage the height and width of a zone is to make it the
same as the area targeted on the canvas by the annotation mapping the zone
onto the canvas.

#### Model

The Shared Canvas model uses:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| sc:Zone         |         | Class     | The class for Zones, which represent part of one or more Canvases |
| exif:height     | height  | Property  | The height component of the aspect ratio of the Zone. Each Zone MUST have exactly one height. |
| exif:width      | width   | Property  | The width component of the aspect ratio of the Zone. Each Zone MUST have exactly one width. |
| rdfs:label      | label   | Property  | A human readable label for the Zone. Each Zone SHOULD have one or more labels. |
| sc:naturalAngle |         | Property  | The angle to which the Zone should be rotated to make the content easier to read for a user. Each sc:Zone MAY have exactly one sc:naturalAngle property and MUST NOT have more than one. This property is not used by the Shelley-Godwin Archive |

The Shelley-Godwin Archive augments this model with:

| Vocabulary Item | JSON-LD   | Type      | Description |
| --------------- |---------- | --------- | ----------- |
| sga:TextZone    |           | Class     | The class for zones using text-based coordinates. |

#### RDF

```turtle
_:zone1 a sc:Zone ;
  exif:height "..." ;
  exif:width "..." ;
  rdfs:label "..." ;
  sc:naturalAngle "..." .
```

The Shelley-Godwin Archive does not use Zones in the October, 2013, 
manifests.

#### JSON-LD

```coffee
{
  id    : "_:zone1"
  a     : "sga:TextZone"
  height: "..."
  width : "..."
  label : "..."
}
```

Note that the `sga:TextZone` class takes an optional height in nominal lines
and an optional width in nominal characters. Interlinear additions do not
count as nominal lines and should have fractional line numbers. When height
and width are missing, the text zone should use a standard font and allow
scrolling when text overflows the target bounding box. If height and width
are provided, they should be used to guide the display of a portion of the
text painted into the text zone.

Fractional line numbers indicate interlinear text that should be bound
visually to the nearest whole line number. For example, line 0.3 is below
line 0 and closer to line 0 than to line 1. Generally, the following formula
can be used to determine relative distance between the whole line and the
fractional line. It is designed to have a half line number be equidistant
between the two whole line numbers (e.g., line 1.5 will be equidistant
between line 1 and line 2 and thus have no deviation from the normal layout).

```coffee
partial_y = y - Math.floor(y) - 0.5
marginEm = switch
  when partial_y > 0
    partial_y - 0.5 * (2 * partial_y)**(2*k)
  when partial_y < 0
    partial_y + 0.5 * (2 * partial_y)**(2*k)
  else
    0
```

This formula tends to cluster associated lines together. It can be loosened
or tightened a bit by changing the exponent (`k`). The value of `marginEm`
should be considered the amount of margin to add/remove above or below the
line to bind it appropriately to the proper nominal line. When the number is
greater than zero, then it represents the amount of space to remove between
the interlinear line and the following line. When the number is less than
zero, then its absolute value represents the amount of space to remove from
between the interlinear line and the preceding line.

Line numbers start at zero at the top of the text zone and increase down,
following the manner of numbering lines in text.

Generally, interlinear lines associated with the following line should be
positioned on a line that is 0.3 less than the following line. Interlinear
lines associated with the previous line should be position on a line that is
0.3 more than the previous line. For example, an addition that is positioned
above line 3 and associated with line 3 should target line 2.7 of the text
zone.

## Annotations

### Image Annotations

Image annotations are just annotations that map an image onto a zone or
canvas. For the Shelley-Godwin Archive, we're mapped the full image onto the 
full canvas, so that's what the examples do here.

#### RDF

```turtle
_:imageAnnotation1 a sc:ContentAnnotation, oa:Annotation ;
  oa:motivatedBy sc:painting ;
  oa:hasBody <imgUrl> ;
  oa:hasTarget _:canvas1 .

<imgUrl1> a dctypes:Image ;
  dc:format "image/jpeg" .
```

#### JSON-LD

```json
{
  id : "_:imageAnnotation1"
  a  : "oa:Annotation"
  motivation: "sc:painting"
  resource: 
    id: <imgUrl>
    a : "dctypes:Image"
    format: "image/jpeg"
  on : "_:canvas1"
}
```

Note that we no longer use an RDF class to indicate that this annotation is
mapping an image onto the canvas.

### Text Annotations

In general, text annotations in Shared Canvas follow the conventions of the
Open Annotation specification with the addition of a motivation denoting that
the annotation is part of the facsimile and not part of the scholarly
commentary about the facsimile.

According to the specification:

> The text should be normalized to a readable string before counting
> characters. HTML/XML tags should be removed, character entities should be
> reduced to the character that they encode, redundant whitespace should be
> normalized, and so forth. This allows the Selector to be used with
> different formats and still have the same semantics and utility.

The concept of a "character" can be problematic in Unicode implementations,
but the Shelley-Godwin Archive does not use any characters that cause
problems using typical JavaScript implementations in browsers.

`_sp:Target1` can be a canvas or a zone, depending on what we're associating
the text with. The oa:hasSource property should provide the URL of the TEI
file that we can fetch to supply the content we draw on the screen.

We can constrain the target of the text annotation instead of using an
intermediate zone if we don't want to aggregate annotations for an area of
the canvas.

#### RDF

```turtle
_:textAnnotation1 a sc:ContentAnnotation, oa:Annotation ;
  oa:hasBody _:text1 ;
  oa:hasTarget _:spTarget1 .

_:text1 a oa:SpecificResource, dctypes:Text ;
  oa:hasSource <teiFile> ;
  oa:hasSelector _:selector1 .

_:selector1 a oax:TextOffsetSelector ;
  oax:begin "..." ;
  oax:end "..." .

_:spTarget1 a oa:SpecificResource ;
  oa:hasSource _:canvas1 ;
  oa:hasSelector _:selector1 .

_:selector1 a oa:FragmentSelector ;
  rdf:value "xywh=200,0,300,200" .
```

#### JSON-LD

Note that targeting the canvas is deprecated for the Shelley-Godwin Archive
transcription annotations. Instead, manifests should target a `sga:TextZone` 
and provide character-based coordinates as part of the target.

```coffee
{
  id: "_:textAnnotation1"
  a: "oa:Annotation"
  motivation: "sc:painting"
  resource:
    a: [ "oa:SpecificResource", "dctypes:Text" ]
    full: "http://shelleygodwinarchive.org/data/tei/ox/ox-tei-1.xml"
    selector:
      a: "oa:TextOffsetSelector"
      start: "..."
      end: "..."
  on:
    a   : "oa:SpecificResource"
    full: "_:canvas1"
    selector:
      a    : "oa:FragmentSelector"
      value: "xywh=200,0,300,200"
}
```

### Text Structuring Annotations (October, 2013 manifests)

For the manifests published in October, 2013, we used bodiless annotations to
note where text should be structured a particular way. For these, we can
develop a simple template that should handle most of the features we need. We
can swap out the SGA-specific class that we use (for now) for the different
types of structure we need to annotate. Text should be normalized for these
annotations in the same way it is normalized for the preceding text 
annotations.

```turtle
_:structureAnnotation1 a oa:Annotation, oax:Highlight, sga:XXXAnnotation ;
  oa:hasTarget _:target1 .

_:target1 a oa:SpecificResource ;
  oa:hasSource http://example.com/tei-file.xml ;
  oa:hasSelector _:selector1 .

_:selector1 a oax:TextOffsetSelector ;
  oax:begin "..." ;
  oax:end "..." .
```

If we need additional information about the annotation, for example
information about which hand was used in a particular section, then we can
add a structured body to the annotation. For now, we'll not worry about that.

The `full` URL should be the URL of the TEI file from which we are getting
the text that we are targeting. This should be the same URL as the TEI file
we used in the body of the content annotations. We use this to tie these
annotations to the unstructured text content annotations.

For now, the OA specification has style information attached to the target
(http://www.openannotation.org/spec/core/#Style). If we want to add some CSS
styles to a highlight annotation, we would modify the target as follows using
content in RDF:

```turtle
_:textTarget1 a oa:SpecificResource ;
  oa:hasSource http://example.com/tei-file.xml ;
  oa_hasStyle _:cssStyle ;
  oa:hasSelector _:selector .

_:cssStyle a oa:Style, cnt:ContentAsText ;
  cnt:chars "vertical-align: super|sub;" ;
  dc:format "text/css" .
```

The `sga:XXXAnnotation` class is take from the additions that the
Shelley-Godwin Archive made to the model below.

#### Model

In accordance with recommendations from the Open Annotation W3C Community
Group, the most recent Shared Canvas data model specification does not use
different classes to indicate different types of annotations. However, the
Archive developed its use of the Shared Canvas data model before this change
and uses a number of classes to indicate the type of material being
associated with the canvas.

The Shelley-Godwin Archive uses:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| sc:ContentAnnotation |         | Class | The class for annotations that have a body consisting of text. |
| sc:ImageAnnotation   |         | Class | The class for annotations that have a body consisting of an image. |
| sc:ZoneAnnotation    |         | Class | The class for annotations that have a body consisting of a zone. |

The Shelley-Godwin Archive uses the following to annotate the text in the body
of an annotation with the class `sc:ContentAnnotation`. Eventually, these will
be changed to motivations or other forms of annotation instead of RDF classes.

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| sga:AdditionAnnotation |         | Class | The class for annotations highlighting text marking it as an addition. |
| sga:DeletionAnnotation |         | Class | The class for annotations highlighting text marking it as a deletion. |
| sga:SearchAnnotation   |         | Class | The class for annotations highlighting text marking it as a search match. |
| sga:LineAnnotation     |         | Class | The class for annotations highlighting text marking it as comprising a line of text. |
| sga:LineBreak          |         | Class | The class for annotations pointing to a break in lines in a span of text. |

### Text Structuring Annotations (JSON-LD)

Instead of using only highlight annotations to mark up the text, the new data
model uses a text zone as the target of the content annotations. This text
zone uses text lines and character columns to allow relative positioning of
text on the canvas.

Whereas the JavaScript viewer needed to calculate line numbers and relative
positioning of text using the October, 2013, manifests, the line numbers and
character offsets are provided in the annotation targets and determined by
the scripts creating the manifests.

In the JSON-LD manifests, only deletions and search results use highlights.
All other annotations, namely lines and additions, paint a text zone with the
applicable text. In some cases, such as when a line of text is interrupted in
the TEI by an addition, the body of the annotation may point to several
disconnected sections of the TEI. In those cases, all of the text should be
strung together as a single text and flowed into the target space.

Highlight annotations for deletions and search results target spans of text
in the TEI. They should still have a motivation of `sc:painting` to indicate
that they are not commentary about the text.

```coffee
[{
  id        : "_:textZoneAnnotation"
  a         : "oa:Annotation"
  motivation: "sc:painting"
  resource:
    id    : "_:textZone1"
    a     : "sga:TextZone"
    width : "..."
    height: "..."
    label : "..."
  on:
    a   : "oa:SpecificResource"
    full: "_:canvas1"
    selector:
      a    : "oa:FragmentSelector"
      value: "xywh=200,0,300,200"
},
{
  id        : "_:textAnnotation1"
  a         : "oa:Annotation"
  motivation: "sc:painting"
  resource:
    a   : "oa:SpecificResource"
    full: "http://example.com/tei-file.xml"
    selector:
      a    : "oa:TextOffsetSelector"
      start: "..."
      end  : "..."
  on:
    a   : "oa:SpecificResource"
    full: "_:textZone1"
    selector:
      a    : "oa:FragmentSelector"
      value: "xy=0,3"
}]
```

This would place the text at the range in the specified TEI file at a
position in the text zone that is at the beginning of nominal line 3.

Highlight annotations are similar to the October, 2013, method:

```coffee
{
  id : "_:textAnnotation2"
  a  : "oa:Annotation"
  motivation: [ "sc:painting", "sga:deleting" ]
  on :
    a : "oa:SpecificResource"
    full: "http://example.com/tei-file.xml"
    selector:
      a: "oa:TextOffsetSelector"
      start: "..."
      end  : "..."
}
```

The primary difference is that we have two motivations indicating that this
annotation is designed for affecting the display of the facsimile and that
the annotation is motivated by the deletion of some text.

### Example Normalization of TEI for Text Annotations

The original TEI file:

```xml
<?xml version="1.0" encoding="ISO-8859-1"?><?xml-model href="../../derivatives/shelley-godwin-page.rnc"
           type="application/relax-ng-compact-syntax"?><?xml-stylesheet type="text/xsl"
           href="../../xsl/page-proof.xsl"
       ?>
<surface xmlns="http://www.tei-c.org/ns/1.0" xmlns:sga="http://sga.mith.org/ns/1.0"
  xml:id="ox-ms_abinger_c56-0001" ulx="0" uly="0" lrx="5078" lry="7304" partOf="#ox-ms_abinger_c56">
  <graphic url="../../images/ox/ox-ms_abinger_c56-0001.tif"/>
  <zone type="library">
    <line><del rend="strikethrough">A12</del></line>
    <line>A 11</line>
    <line><unclear unit="chars" extent="1"/> Autograph</line>
    <line>__________</line>
    <line>Part of the MS of</line>
    <line>Frankenstein</line>
    <line> __________</line>
    <line>pp 64-172 (of vol I.?)</line>
    <line>ch. 6-17</line>
    <line>vol. II. pp 1-150</line>
    <line>ch I-XIV</line>
    <line>Corrections in another</line>
    <line>hand</line>
    <line>Dep. c. 477/1</line>
  </zone>
</surface>
```

Normalized, placed into rows of ten characters bracketed by ‘[’ and ‘]’.
I've collapsed tags and space into a single space except where a space
seemed significant within a tag. This might not be accurate or a reasonable
algorithm since we cantt know for sure what is a significant space within an
element.

```
000-009 [   A12 A 1]
010-019 [1  Autogra]
020-029 [ph _______]
030-039 [___ Part o]
040-049 [f the MS o]
050-059 [f Frankens]
060-069 [tein  ____]
070-079 [______ pp ]
080-089 [64-172 (of]
090-099 [ vol I.?) ]
100-109 [ch. 6-17 v]
110-119 [ol. II. pp]
120-129 [ 1-150 ch ]
130-139 [I-XIV Corr]
140-149 [ections in]
150-159 [ another h]
160-169 [and Dep. c]
170-178 [. 477/1  ]
```

### Motivations

The most recent Shared Canvas data model makes use of the `oa:motivatedBy`
property of the annotation to indicate the purpose of the annotation.

The Shared Canvas data model uses:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| sc:painting     |         | Instance  | [instance of oa:Motivation] The motivation that represents the distinction between resources that should be painted onto the Canvas, rather than resources that are about the Canvas. If the target of the Annotation is not a Canvas or Zone, then the meaning is left to other communities to define. |

The Shelley-Godwin Archive augments this model with:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| sga:adding      |            | Instance  | [instance of oa:Motivation; broader motivation is oa:editing] The motivation that represents text marked in the TEI transcription as being added at the target position. The added text is the body of the annotation. |
| sga:deleting    |            | Instance  | [instance of oa:Motivation; broader motivation is oa:editing] The motivation that represents text marked in the TEI transcription as being deleted. The annotation is a highlight, targeting the text that is being deleted. |
| sga:modification |           | Instance  | [instance of oa:Motivation; broader motivation is oa:editing] The motivation that represents the replacement of a span of text with another text in the TEI transcription. The replacement text is the body of the annotation, and the replaced text is selected as the target. |
| sga:reading     |            | Instance  | [instance of oa:Motivation] The motivation that represents the distinction between resources that should be used as a reading text, rather than resources that should be painted onto the Canvas. |
| sga:searching   |            | Instance  | |
| sga:source      |            | Instance  | [instance of oa:Motivation] The motivation that represents the distinction between resources that represent the master TEI-GE from which the reading and painted text are derived, rather than resources that should be painted onto the Canvas. |

#### sga:adding

This motivation replaces the sga:AdditionAnnotation class. The target should
be a TextZone.

#### sga:deleting

This motivation replaces the sga:DeletionAnnotation class. The target should
be a span of text within a TEI document.

#### sga:modification

This motivation combines two annotations formerly of classes
sga:AdditionAnnotation and sga:DeletionAnnotation when doing so more
faithfully reflects the intent of the TEI transcription. This allows the two
to be linked together for a better user experience. The target should be a
span of text within a TEI document.

#### sc:painting

The `sc:painting` motivation is the standard motivation for annotations
placing elements on the canvas or zone. This is used to indicate that an
annotation with an image, zone, or text body and targeting a canvas or zone
is linking the body to the target for the purpose of painting the body onto
the target.

This motivation replaces the sga:LineAnnotation class when the target is a
TextZone.

#### sga:reading

The `sga:reading` motivation indicates annotations that connect an HTML
document with a canvas where the HTML document represents a clean reading
text of the associated transcription.

#### sga:source

The `sga:source` motivation indicates annotations that connect a TEI (XML)
document with a canvas where the TEI document represents the scholarly
digital transcription of the physical text in or on the artifact represented
by the canvas.

#### sga:searching


## Ordering Model

### Ordered Aggregations

URI pattern: http://shelleygodwinarchive.org/data/{manifest_id}/list/{name}.json

Ordered aggregations of annotations or other content should be represented by
a RDF list.

#### JSON-LD

```json
{
  id: "http://shelleygodwinarchive.org/data/{manifest_id}/list/{name}"
  @type: "sc:AnnotationList"
  resources: [
    # list of annotations
  ]
}
```

### Sequences

URL pattern: http://shelleygodwinarchive.org/data/{manifest_id}/sequences/{name}.json

The Sequence conveys the ordering of the pages. The default sequence (and
typically the only sequence) should be embedded within the Manifest, but may
also be available from its own URI. Any additional sequences should be
referred to from the Manifest but not embedded within it.

The {name} parameter in the URI structure is to distinguish it from any other
sequences that may be available for the physical object. Typical default
names are "normal" or "basic". Names should not begin with a number, as it
cannot be the first character of an XML tag making RDF/XML serialization
impossible.

Sequences may have their own descriptive, rights and linking metadata using
the same fields as for Manifests. The Label field should be given for all
sequences and must be given if there is more than one referenced from a
Manifest. After the metadata, the set of pages in the object, represented by
Canvas resources, are listed in order in the JSON-LD "canvases" property or
the RDF list construct in the October, 2013, manifests.

#### RDF

```turtle
_:sequence1 a sc:Sequence, rdf:List ;
  rdfs:label "..." ;
  ore:aggregates _:canvas1, _:canvas2, _:canvas3 ;
  rdf:first _:canvas1 ;
  rdf:rest ( _:canvas2, _:canvas3 ) .
```

#### JSON-LD

```json
{
  id       : "_:sequence1"
  a        : "sc:Sequence"
  label    : "..."
  viewingDirection : "left-to-right"
  viewingHint      : "paged"
  canvases : [
    "_:canvas1"
    "_:canvas2"
    "_:canvas3"
  ]
}
```

### Ranges

URL pattern: http://shelleygodwinarchive.org/data/{manifest_id}/ranges/{name}.json

A range is a subset of a sequence. It has almost the same structure as a
sequence, but only lists the canvases in the range. Ranges need not be
contiguous. They may contain parts of a canvas represented by
`oa:SpecificResource` targets.

In this example, we have a range that covers part of the first canvas and all
of the second and third canvas.

#### RDF

```turtle
_:range1 a sc:Range, ore:Aggregation, rdf:List ;
  dcterms:isPartOf _:sequence1 ;
  ore:aggregates _:cavasPart1, _:canvas2, _:canvas3 ;
  rdf:first _:canvasPart1 ;
  rdf:rest ( _:canvas2, _:canvas3 ) .

_:canvasPart1 a oa:SpecificResource ;
  oa:hasSource _:canvas1 ;
  oa:hasSelector _:selector1 .

_:selector1 a oa:FragmentSelector ;
  rdf:value "xywh=400,0,200,800" .
```

#### JSON-LD

```coffee
{
  id    : "_:range1"
  a     : "sc:Range"
  label : "..."
  within: "_:sequence1"
  canvases: [
    "_:canvas1#xywh=400,0,200,800"
    "_:canvas2"
    "_:canvas3"
  ]
}
```

## Discovery Model

When using RDF (JSON, XML, or other triple-oriented serialization format),
the application should look for the node whose URI is the same as the URI of
the manifest file. This node MAY use `ore:describes` to point to the URI of
the manifest node, in which case the application should use that URI for
further discovery.

When using JSON-LD, the JSON document SHOULD be structured in such a way that
the manifest node provides the primary structure of the document. For the 
S-GA Shared Canvas viewer, the JSON document MUST be structured in such a
way that the manifest node provides the primary structure of the document.

Everything that is considered part of the Shared Canvas view should be
discoverable by following links from the manifest URI or by following links
to the manifest URI (properties pointing from or to nodes in such a way that
a path can be drawn from the manifest URI to the content in question
regardless of the direction of the property). 

This is tricky when considering annotations of text when the constraints
between target and body are not strictly equal. In those cases, the
constraints should be tested for overlaps, and the overlaps used to determine
to what extent an annotation applies in a particular context.

### Annotation Lists

Lists are useful for grouping related annotations that might fall across
different layers or apply to different aspects of a digital facsimile 
edition.

Annotations may use the `within` property to assert that the annotation
belongs in a layer.

### Layers

URL pattern: http://shelleygodwinarchive.org/data/layers/{name}.json

A layer is a collection of annotations and annotation lists that should be
considered part of a coordinated set of annotations.

A layer must have a human-readable label.

#### RDF

```turtle
_:layer1  sc:Layer, ore:Aggregation ;
  rdfs:label "..." ;
  ore:aggregates _:anno1, _:anno2, _:anno3 .
```

#### JSON-LD

```json
{
  id: "_:layer1"
  a: "sc:Layer"
  label: "..."
}
```

### Manifests

URL pattern: http://shelleygodwinarchive.org/data/{manifest_id}/manifest.json

When parsing a Shared Canvas manifest, the viewer begins with the manifest
resource URL and follows the properties to aggregations. The resources
aggregated by the manifest are themselves typically aggregations of the
resources we're interested in: canvases, annotations, images.

Here, the sequence is the normal ordering of canvases. The ranges represent
the subsets of canvases contained in each of the notebooks. The zone
annotations lists each of the annotations mapping the zones to the canvases.
The text annotations are mapping the base text onto the zones. The image
annotations are mapping the images onto the canvases.

The Shared Canvas data model is evolving in a direction that removes the
media aspect of the annotation from the decision process as to which list the
annotation appears in. So we will eventually get to the point where the image
annotations aren't in a list of image annotations because they are images,
but because the annotation list happens to revolve around a particular
semantic relating the images to the canvas: original light, 1990 scans, 2010
scans, etc., providing options for someone assembling an edition.

The dc:* properties are where we can insert arbitrary Dublin Core properties
that describe the manifest resource (e.g., who assembled the manifest - who
is asserting that these resources should be brought together to construct a
scholarly edition?).

The "rdfs:label" is a human readable string describing the content
represented by the manifest. It's like a book title or similar label.
According to the current spec (as of 20 June 2013), each manifest MUST have
1 or more rdfs:label properties.

#### MODEL

The Shared Canvas data model uses:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| sc:Manifest     |         | Class     | An ordered aggregation of Annotations. |
| sc:forCanvas    |         | Relationship | The relationship between the AnnotationList and the Canvases which are the targets of the included Annotations. Typically this relationship is used to describe the AnnotationList in a Manifest to allow clients to determine which lists should be retrieved. |
| rdfs:label      | label   | Property  | A human readable label for the Manifest. Each Manifest MUST have one or more labels. |

The Shelley-Godwin Archive augments this model with:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| dc:title        | title      | Property  | The human readable label intended to convey the primary work with which this manifest is associated. |
| sc:agentLabel  | agent | Property  | The human readable label intended to convey the primary author(s) of the work represented by the manifest. |
| sga:handLabel   | hand  | Property | The human readable label intended to convey the predominant hand in which the content represented by the manifest was written. |
| sga:stateLabel  | state | Property | A label indicating the completeness and/or trustworthiness of the transcription and metadata associated with the manifest. |
| sc:attributionLabel | attribution | Property | A human readable label intended to convey the primary institution holding the physical object represented by the manifest. |
| sga:shelfmarkLabel | shelfmark  | Property | A human readable label intended to convey the identification of the physical aggregation containing the object represented by this manifest within the primary institution. |

#### RDF

```turtle
<manifest1> a sc:Manifest, ore:Aggregation
  dc:* ... ;
  sc:forCanvas _:canvas1, _:canvas2, _:canvas3 ;
  rdfs:label "..." ;
  ore:aggregates _:sequence1, _:range1, _:range2, _:zoneAnnotations1,
                 _:zoneAnnotations2, _:textAnnotations1, _:imageAnnotations1 .
```

#### JSON-LD

```coffee
{
  id   : "http://shelleygodwinarchive.org/data/manifest1/manifest.json"
  a    : "sc:Manifest"
  label: "..."
  sequences: [ {
    a       : "sc:Sequence"
    label   : "..."
    canvases: [ ... ]
  } ]
  canvases: [ ... ]
  structures: [ ... ]
  otherContent: [ ... ]
}
```

### Collections

## Services and Bibliographic Information

The Shared Canvas data model uses:

| Vocabulary Item | JSON-LD    | Type      | Description |
| --------------- | ---------- | --------- | ----------- |
| sc:hasRelatedService | service | Relationship | The relationship between a resource in the Shared Canvas model and the endpoint for a related service. |

The Shelley-Godwin Archive understands the following service profiles:

| Service | Status | Profile URI |
| ------- | ------ | ----------- |
| Djatoka | Implemented | http://sourceforge.net/projects/djatoka/ |
| IIIF    | Pending     | http://library.stanford.edu/iiif/image-api/1.1/compliance.html |

### Djatoka Service

The Archive uses JPEG2000 images to provide zooming and panning using a tiled
image viewer. All JPEG2000 URLs have a `sc:hasRelatedService` property
providing information about the rendering server and image type. The
following JSON-LD example assumes that more than one image will reference
the djatoka service.

#### RDF

```turtle
<http://example.com/image.jp2> a dctypes:Image ;
  sc:hasRelatedService <http://tiles2.bodleian.ox.ac.uk:8080/adore-djatoka/resolver> .
<http://tiles2.bodleian.ox.ac.uk:8080/adore-djatoka/resolver> 
  dcterms:conformsTo <http://sourceforge.net/projects/djatoka/> .
```

#### JSON-LD

```coffee
[{
  id     : "http://example.com/image.jp2"
  service: "http://tiles2.bodleian.ox.ac.uk:8080/adore-djatoka/resolver"
},
{ id     : "http://tiles2.bodleian.ox.ac.uk:8080/adore-djatoka/resolver"
  profile: "http://sourceforge.net/projects/djatoka/"
}]
```

### IIIF

Images that are available through a IIIF service will have a
`sc:hasRelatedService` property pointing to the service endpoint. Images
served through an IIIF service can be used in a panning and zooming
interface. The following JSON-LD example assumes that more than one image
will reference the IIIF service.

#### JSON-LD

```coffee
[{
  id     : "http://example.com/image.jp2"
  service: "http://example.com/iiif"
},
{ id     : "http://example.com/iiif"
  profile: "http://library.stanford.edu/iiif/image-api/1.1/compliance.html"
}]
```