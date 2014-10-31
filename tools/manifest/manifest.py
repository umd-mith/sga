#!/usr/bin/env python

import sys

from six.moves.urllib.parse import urljoin

from xml.sax import make_parser
from xml.sax.handler import ContentHandler
from xml.etree import ElementTree as etree

XI = 'http://www.w3.org/2001/XInclude'


class Manifest(object):

    def __init__(self, tei_filename):
        self.canvases = []
        self.doc = etree.parse(tei_filename).getroot()
        for inc in self.doc.findall('.//{%s}include' % XI):
            filename = urljoin(tei_filename, inc.attrib['href'])
            canvas = Canvas(filename)
            self.canvases.append(canvas)


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


if __name__ == "__main__":
    tei_file = sys.argv[1]
    m = Manifest(tei_file)
    # TODO: print out JSON-LD :)


