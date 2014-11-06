#!/usr/bin/env python

import sys

from six.moves.urllib.parse import urljoin

from xml.sax import make_parser
from xml.sax.handler import ContentHandler
from xml.etree import ElementTree as etree

from rdflib.plugin import register, Parser, Serializer
from rdflib import ConjunctiveGraph, Namespace, URIRef, RDF, BNode

XI = 'http://www.w3.org/2001/XInclude'
SC = Namespace('http://www.shared-canvas.org/ns/')

class Manifest(object):

    def __init__(self, tei_filename):
        self.canvases = []
        self.doc = etree.parse(tei_filename).getroot()
        for inc in self.doc.findall('.//{%s}include' % XI):
            filename = urljoin(tei_filename, inc.attrib['href'])
            canvas = Canvas(filename)
            self.canvases.append(canvas)

    def jsonld(self, manifest_uri):
        g = self.rdf(manifest_uri)
        return g.serialize(context=context(), format='json-ld')

    def rdf(self, manifest_uri):
        manifest_uri = URIRef(manifest_uri)
        g = ConjunctiveGraph()
        g.add((manifest_uri, RDF.type, SC.Manifest))
        for canvas in self.canvases:
            canvas_uri = BNode()
            g.add((manifest_uri, SC.hasCanvases, canvas_uri))
            g.add((canvas_uri, RDF.type, SC.Canvas))
        return g

class Canvas(object):

    def __init__(self, tei_filename):
        parser = make_parser()
        handler = CanvasHandler(tei_filename)
        parser.setContentHandler(handler)
        parser.parse(open(tei_filename))
        self.zones = handler.zones


class Zone(object):

    def __init__(self):
        self.lines = []


class Line(object):
    
    def __init__(self):
        self.begin = 0
        self.end = 0
        self.text = ""


class CanvasHandler(ContentHandler):
    """
    SAX Handler for extracting zones and lines from a TEI canvas.
    """

    def __init__(self, filename):
        self.filename = filename
        self.zones = []
        self.pos = 0
        self.in_line = False

    def startElement(self, name, attrs):
        if name == "zone":
            self.zones.append(Zone())
        elif name == "line":
            self.in_line = True
            l = Line()
            l.begin = self.pos
            self.zones[-1].lines.append(l)

    def endElement(self, name):
        if name == "line":
            self.zones[-1].lines[-1].end = self.pos
            self.in_line = False
   
    def characters(self, content):
        self.pos += len(content) # TODO: unicode characters?
        if self.in_line:
            self.zones[-1].lines[-1].text += content


def context():
  # TODO: pare this down, and make it more sane over time
  return {
    "sc" : "http://www.shared-canvas.org/ns/",
    "sga" : "http://www.shelleygodwinarchive.org/ns1#",
    "ore" : "http://www.openarchives.org/ore/terms/",
    "exif" : "http://www.w3.org/2003/12/exif/ns#",
    "iiif" : "http://library.stanford.edu/iiif/image-api/ns/",
    "oa" : "http://www.w3.org/ns/openannotation/core/",
    "oax" : "http://www.w3.org/ns/openannotation/extension/",
    "cnt" : "http://www.w3.org/2011/content#",
    "dc" : "http://purl.org/dc/elements/1.1/",
    "dcterms" : "http://purl.org/dc/terms/",
    "dctypes" : "http://purl.org/dc/dcmitype/",
    "foaf" : "http://xmlns.com/foaf/0.1/",
    "rdf" : "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rdfs" : "http://www.w3.org/2000/01/rdf-schema#",
    "skos" : "http://www.w3.org/2004/02/skos/core#",
    "xsd" : "http://www.w3.org/2001/XMLSchema#",
    "license" : {
      "@type" : "@id",
      "@id" : "dcterms:license"
    },
    "service" : {
      "@type" : "@id",
      "@id" : "sc:hasRelatedService"
    },
    "seeAlso" : {
      "@type" : "@id",
      "@id" : "sc:hasRelatedDescription"
    },
    "within" : {
      "@type" : "@id",
      "@id" : "dcterms:isPartOf"
    },
    "profile" : {
      "@type" : "@id",
      "@id" : "dcterms:conformsTo"
    },
    "sequences" : {
      "@type" : "@id",
      "@id" : "sc:hasSequences",
      "@container" : "@list"
    },
    "canvases" : {
      "@type" : "@id",
      "@id" : "sc:hasCanvases",
      "@container" : "@list"
    },
    "resources" : {
      "@type" : "@id",
      "@id" : "sc:hasAnnotations",
      "@container" : "@list"
    },
    "images" : {
      "@type" : "@id",
      "@id" : "sc:hasImageAnnotations",
      "@container" : "@list"
    },
    "otherContent" : {
      "@type" : "@id",
      "@id" : "sc:hasLists",
      "@container" : "@list"
    },
    "structures" : {
      "@type" : "@id",
      "@id" : "sc:hasRanges",
      "@container" : "@list"
    },
    "metadata" : {
      "@type" : "@id",
      "@id" : "sc:metadataLabels",
      "@container" : "@list"
    },
    "description" : "dc:description",
    "attribution" : "sc:attributionLabel",
    "height" : {
      "@type" : "xsd:int",
      "@id" : "exif:height"
    },
    "width" : {
      "@type" : "xsd:int",
      "@id" : "exif:width"
    },
    "viewingDirection" : "sc:viewingDirection",
    "viewingHint" : "sc:viewingHint",
    "tile_height" : {
      "@type" : "xsd:integer",
      "@id" : "iiif:tileHeight"
    },
    "tile_width" : {
      "@type" : "xsd:integer",
      "@id" : "iiif:tileWidth"
    },
    "scale_factors" : {
      "@id" : "iiif:scaleFactor",
      "@container" : "@list"
    },
    "formats" : {
      "@id" : "iiif:formats",
      "@container" : "@list"
    },
    "qualities" : {
      "@id" : "iiif:qualities",
      "@container" : "@list"
    },
    "motivation" : {
      "@type" : "@id",
      "@id" : "oa:motivatedBy"
    },
    "resource" : {
      "@type" : "@id",
      "@id" : "oa:hasBody"
    },
    "on" : {
      "@type" : "@id",
      "@id" : "oa:hasTarget"
    },
    "full" : {
      "@type" : "@id",
      "@id" : "oa:hasSource"
    },
    "selector" : {
      "@type" : "@id",
      "@id" : "oa:hasSelector"
    },
    "stylesheet" : {
      "@type" : "@id",
      "@id" : "oa:styledBy"
    },
    "style" : "oa:styleClass",
    "painting" : "sc:painting",
    "hasState" : {
      "@type" : "@id",
      "@id" : "oa:hasState"
    },
    "hasScope" : {
      "@type" : "@id",
      "@id" : "oa:hasScope"
    },
    "annotatedBy" : {
      "@type" : "@id",
      "@id" : "oa:annotatedBy"
    },
    "serializedBy" : {
      "@type" : "@id",
      "@id" : "oa:serializedBy"
    },
    "equivalentTo" : {
      "@type" : "@id",
      "@id" : "oa:equivalentTo"
    },
    "cachedSource" : {
      "@type" : "@id",
      "@id" : "oa:cachedSource"
    },
    "conformsTo" : {
      "@type" : "@id",
      "@id" : "dcterms:conformsTo"
    },
    "default" : {
      "@type" : "@id",
      "@id" : "oa:default"
    },
    "item" : {
      "@type" : "@id",
      "@id" : "oa:item"
    },
    "first" : {
      "@type" : "@id",
      "@id" : "rdf:first"
    },
    "rest" : {
      "@type" : "@id",
      "@id" : "rdf:rest",
      "@container" : "@list"
    },
    "beginOffset" : {
      "@type" : "xsd:int",
      "@id" : "oax:begin"
    },
    "endOffset" : {
      "@type" : "xsd:int",
      "@id" : "oax:end"
    },
    "textOffsetSelector" : {
      "@type" : "@id",
      "@id" : "oax:TextOffsetSelector"
    },
    "chars" : "cnt:chars",
    "encoding" : "cnt:characterEncoding",
    "bytes" : "cnt:bytes",
    "format" : "dc:format",
    "language" : "dc:language",
    "annotatedAt" : "oa:annotatedAt",
    "serializedAt" : "oa:serializedAt",
    "when" : "oa:when",
    "value" : "rdf:value",
    "start" : "oa:start",
    "end" : "oa:end",
    "exact" : "oa:exact",
    "prefix" : "oa:prefix",
    "suffix" : "oa:suffix",
    "label" : "rdfs:label",
    "name" : "foaf:name",
    "mbox" : "foaf:mbox"
  }

register('json-ld', Serializer, 'rdflib_jsonld.serializer', 'JsonLDSerializer')

if __name__ == "__main__":
    tei_file = sys.argv[1]
    m = Manifest(tei_file)
    # TODO: print out JSON-LD :)


