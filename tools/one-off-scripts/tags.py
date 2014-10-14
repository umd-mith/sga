#!/usr/bin/env python

"""
A crazy little script to summarize what tags are used in the SGA TEI data.
"""

import os
import re
import xml.etree.ElementTree as etree

class XmlSum():

    def __init__(self):
        self.s = {}

    def summarize(self, path):
        doc = etree.parse(path)
        self.add(doc.getroot())

    def add(self, e):
        ns, tag = re.match("(?:{(.+)})(.+)", e.tag).groups()
        self.tally(ns)
        self.tally(ns, tag)
        for name, value in e.attrib.items():
            self.tally(ns, tag, name)
            self.tally(ns, tag, name, value)
        for child in e:
            self.add(child)
    
    def tally(self, *keys):
        d = self.s
        for k in keys:
            if k not in d:
                d[k] = {"___count": 0}
            d = d[k]
        d["___count"] = d["___count"] + 1

    def report(self):
        namespaces = []
        for ns in self._keys(self.s):
            print "%s [%s]" % (ns, self.s[ns]["___count"])
            for tag in self._keys(self.s[ns]):
                print " %s [%s]" % (tag, self.s[ns][tag]["___count"])
                for attribute in self._keys(self.s[ns][tag]):
                    print "  %s [%s]" % (attribute, self.s[ns][tag][attribute]["___count"])

    def _keys(self, d):
        keys = d.keys()
        if '___count' in keys:
            keys.pop(keys.index('___count'))
        keys.sort(lambda a, b: cmp(d[b]['___count'], d[a]['___count']))
        return keys


def main():
    xs = XmlSum()
    for dirpath, dirnames, filenames in os.walk("../../data/tei"):
        for filename in filenames:
            path = os.path.join(dirpath, filename)
            if not path.endswith('.xml'):
                continue
            try:
                xs.summarize(path)
            except Exception as e:
                print "%s: %s" % (path, e)

    xs.report()

if __name__ == "__main__":
    main()
