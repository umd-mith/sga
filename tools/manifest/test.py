#!/usr/bin/env python

import pytest

from rdflib.plugin import register, Parser
from rdflib import ConjunctiveGraph, URIRef, RDF

from manifest import Manifest, Canvas
from xml.etree import ElementTree as etree


def test_manifest():
    tei_file = "../../data/tei/ox/ox-frankenstein_notebook_c1.xml"
    m = Manifest(tei_file)
    assert len(m.canvases) == 36

def test_canvas():
    tei_file = "../../data/tei/ox/ox-ms_abinger_c58/ox-ms_abinger_c58-0001.xml"
    c = Canvas(tei_file)
    assert len(c.zones) == 3

    z = c.zones[2]
    assert len(z.lines) == 15

    l = z.lines[0]
    assert l.text == 'satisfied that nothing on earth will have the power'
    assert l.begin == 25
    assert l.end == 76

def test_deletion():
    # TODO: what should we do here?
    tei_file = "../../data/tei/ox/ox-ms_abinger_c58/ox-ms_abinger_c58-0001.xml"
    c = Canvas(tei_file)
    l = c.zones[2].lines[13]

def test_addition():
    # TODO: what should we do here?
    pass

def test_parse_jsonld():
    register('json-ld', Parser, 'rdflib_jsonld.parser', 'JsonLDParser')
    tei_file = "../../data/tei/ox/ox-frankenstein_notebook_c1.xml"
    m = Manifest(tei_file)
    jsonld = m.jsonld('http://example.com/frankenstein.json')

    g = ConjunctiveGraph()
    g.parse(data=jsonld, format='json-ld')

    assert g.value(URIRef('http://example.com/frankenstein.json'), RDF.type) == URIRef('http://www.shared-canvas.org/ns/Manifest')
