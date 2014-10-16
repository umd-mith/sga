#!/usr/bin/env python

"""
A crazy little script to summarize what tags are used in the SGA TEI data
and write it out as HTML.
"""

import os
import re
import sys
import xml.etree.ElementTree as etree

class XmlSum():

    def __init__(self):
        self.doc_count = 0
        self.s = {}

    def summarize(self, path):
        doc = etree.parse(path)
        self.add(doc.getroot())

    def add(self, e):
        self.doc_count += 1
        ns, tag = re.match("(?:{(.+)})(.+)", e.tag).groups()
        self.tally(ns)
        self.tally(ns, tag)
        for attr_name, attr_value in e.attrib.items():
            # attribute strings can be space delimited
            for a in attr_name.split(' '):
                self.tally(ns, tag, a)
                self.tally(ns, tag, a, attr_value)
        for child in e:
            self.add(child)
    
    def tally(self, *keys):
        d = self.s
        for k in keys:
            if k not in d:
                d[k] = {"___count": 0}
            d = d[k]
        d["___count"] = d["___count"] + 1

    def text(self):
        for ns in self._keys(self.s):
            print "%s [%s]" % (ns, self.s[ns]["___count"])
            for tag in self._keys(self.s[ns]):
                print " %s [%s]" % (tag, self.s[ns][tag]["___count"])
                for attribute in self._keys(self.s[ns][tag]):
                    print "  %s [%s]" % (attribute, self.s[ns][tag][attribute]["___count"])

    def html(self):
        print '''
<!doctype html>
<html>
  <head>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css">
    <style>
      body {
        font-size: 14pt;
      }
      ul {
        list-style-type: none;
      }
      ul.attributes {
        list-style-type: disc;
        font-size: smaller;
      }
      .count {
        font-size: smaller;
        font-style: italic;
        font-color: gray;
      }
      .namespace {
        font-size: larger;
        margin-top: 20px;
      }
      .attributes {
        display: none;
      }
      .attribute {
        font-style: italic;
      }
      .glyphicon {
        color: #444444;
      }
    </style>
    </script>
  </head>
  <body>
  <div class="container">
  <h1>XML Summary: %s files</h1>
  <ul class="namespaces">
''' % c(self.doc_count)
        for ns in self._keys(self.s):
            print '  <li><span class="glyphicon glyphicon-plus"></span> <span class="namespace">%s</span> <span class="count">%s</span>' % (ns, c(self.s[ns]["___count"]))
            print '    <ul class="elements">'
            for tag in self._keys(self.s[ns]):
                if ns == "http://www.tei-c.org/ns/1.0":
                    e = '<a href="http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-%s.html">&lt;%s&gt;</a>' % (tag, tag)
                else:
                    e = '&lt;%s&gt;' % tag
                print '      <li><span class="glyphicon glyphicon-plus"></span> <span class="element">%s</span> <span class="count">%s</span>' % (e, c(self.s[ns][tag]["___count"]))
                print '        <ul class="attributes">'
                for attribute in self._keys(self.s[ns][tag]):
                    print '          <li><span class="attribute">%s</span> <span class="count">%s</span>' % (attribute, c(self.s[ns][tag][attribute]["___count"]))
                print '        </ul>'
            print '    </ul>'
        print '''
</ul>
</div>
<script src="https://code.jquery.com/jquery-1.11.0.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
<script>
  $(function() {
    $(".glyphicon").click(function(event) {
      if ($(this).hasClass('glyphicon-plus')) {
        $(this).removeClass('glyphicon-plus');
        $(this).addClass('glyphicon-minus');
      } else {
        $(this).removeClass('glyphicon-minus');
        $(this).addClass('glyphicon-plus');
      }
      $(this).parent().find("ul").each(function(i, ul) {
        ul = $(ul);
        if (ul.is(":visible")) {
          ul.hide();
        } else {
          ul.show();
        }
      });
    });
  });
</script>
</body>
</html>
'''
        

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
                sys.stderr.write("%s: %s\n" % (path, e))

    xs.html()

def c(n):
    "1234 -> 1,234"
    return format(n, ",d")

if __name__ == "__main__":
    main()
