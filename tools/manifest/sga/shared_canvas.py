#!/usr/bin/env python

import sys
import json
import pyld

from rdflib.plugin import register, Parser, Serializer
from rdflib import ConjunctiveGraph, URIRef, RDF, RDFS, BNode, Literal

from .tei import Document
from .namespaces import OA, OAX, ORE, SC, SGA, TEI, EXIF


class Manifest(object):

    def __init__(self, tei_filename, manifest_uri):
        self.tei = Document(tei_filename)
        self.uri = URIRef(manifest_uri)
        self.g = ConjunctiveGraph()
        self._build()

    def jsonld(self, indent=2):
        j = self.g.serialize(format='json-ld')
        j = json.loads(j)
        j = pyld.jsonld.compact(j, self._context())
        return j

    def _build(self):
        self.g.add((self.uri, RDF.type, SC.Manifest))
        # TODO: add manifest level metadata here
        self._add_canvases()

    def _add_canvases(self):
        g = self.g

        sequences_uri = BNode()
        g.add((self.uri, SC.hasSequences, sequences_uri))

        sequence_uri = BNode()
        g.add((sequences_uri, RDF.first, sequence_uri))
        g.add((sequences_uri, RDF.rest, RDF.nil))
        g.add((sequence_uri, RDF.type, SC.Sequence))
        g.add((sequence_uri, RDF.type, RDF.List))
        g.add((sequence_uri, RDFS.label, Literal("Physical sequence")))

        for surface in self.tei.surfaces:

            # add the canvas
            canvas_uri = BNode()
            g.add((self.uri, SC.hasCanvases, canvas_uri))
            g.add((canvas_uri, RDF.type, SC.Canvas))
            g.add((canvas_uri, RDFS.label, Literal(surface.folio)))
            g.add((canvas_uri, SGA.folioLabel, Literal(surface.folio)))
            g.add((canvas_uri, SGA.shelfmarkLabel, Literal(surface.shelfmark)))
            g.add((canvas_uri, EXIF.height, Literal(surface.height)))
            g.add((canvas_uri, EXIF.width, Literal(surface.width)))
          
            # add the image annotation
            image_ann_uri = BNode()
            g.add((image_ann_uri, RDF.type, OA.Annotation))
            g.add((image_ann_uri, OA.hasTarget, canvas_uri))
            g.add((image_ann_uri, OA.hasBody, URIRef(surface.image)))
            g.add((self.uri, SC.hasImageAnnotations, image_ann_uri))

            # add the canvas to the sequence
            g.add((sequence_uri, RDF.first, canvas_uri))
            next_sequence_uri = BNode()
            g.add((sequence_uri, RDF.rest, next_sequence_uri))
            sequence_uri = next_sequence_uri

            # add the zone annotations
            self._add_zone_annotations(surface, canvas_uri)

            # add the line annotations
            self._add_text_annotations(surface)

        # close off the sequence list
        g.add((sequence_uri, RDF.rest, RDF.nil))

    def _add_zone_annotations(self, surface, canvas):
        g = self.g
        annotations = BNode()

        g.add((self.uri, ORE.aggregates, annotations))
        g.add((annotations, RDF.type, SC.AnnotationList))
        g.add((annotations, RDF.type, SC.Layer))

        for zone in surface.zones:
            annotation = BNode()
            g.add((annotations, ORE.aggregates, annotation))
            g.add((annotation, RDF.type, SC.ContentAnnotation))

            body = BNode()
            g.add((annotation, OA.hasBody, body))
            g.add((body, RDF.type, OA.SpecificResource))
            g.add((body, OA.hasSource, URIRef(surface.filename)))

            selector = BNode()
            g.add((body, OA.hasSelector, selector))
            g.add((selector, RDF.type, OAX.TextOffsetSelector))
            g.add((selector, OAX.beginOffset, Literal(zone.begin)))
            g.add((selector, OAX.endOffset, Literal(zone.end)))

            target = BNode()
            g.add((annotation, OA.hasTarget, target))
            g.add((target, RDF.type, OA.SpecificResource))
            g.add((target, OA.hasSource, canvas))

            selector = BNode()
            g.add((target, OA.hasSelector, selector))
            g.add((selector, RDF.type, OA.FragmentSelector))
            g.add((selector, RDF.value, Literal(zone.xywh)))

    def _add_text_annotations(self, surface):
        g = self.g
        annotations = BNode()

        g.add((self.uri, ORE.aggregates, annotations))
        g.add((annotations, RDF.type, SC.AnnotationList))
        g.add((annotations, RDF.type, SC.Layer))

        for zone in surface.zones:

            for line in zone.lines:

                # link AnnotationList to LineAnnotation
                line_annotation = BNode()
                g.add((annotations, ORE.aggregates, line_annotation))
                g.add((line_annotation, RDF.type, SGA.LineAnnotation))
           
                # link LineAnnotation to SpecificResource and TEI file
                target = BNode()
                g.add((line_annotation, OA.hasTarget, target))
                g.add((target, RDF.type, OA.SpecificResource))
                g.add((target, OA.hasSource, URIRef(surface.filename)))

                # link SpecificResource and TextOffsetSelector
                selector = BNode()
                g.add((target, OA.hasSelector, selector))
                g.add((selector, RDF.type, OAX.TextOffsetSelector))
                g.add((selector, OAX.beginOffset, Literal(line.begin)))
                g.add((selector, OAX.endOffset, Literal(line.end)))


    def _context(self):
      # TODO: pare this down, and make it more sane over time
      # We should only be asserting things that are needed by the viewer
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


