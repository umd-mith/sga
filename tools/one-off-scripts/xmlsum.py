#!/usr/bin/env python

"""
A crazy little script that summarizes what tags and attributes are used in the 
SGA TEI data and writes out an HTML report.
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
        self.doc_count += 1
        doc = etree.parse(path)
        self.add(doc.getroot())

    def add(self, e):
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
        d = self.dict(keys)
        d["___count"] += 1

    def count(self, *keys):
        d = self.dict(keys, create=False)
        if not d:
            return 0
        else:
            return d['___count'] 

    def dict(self, keys, create=True):
        d = self.s
        for k in keys:
            if k not in d:
                if create:
                    d[k] = {"___count": 0}
                else:
                    return None
            d = d[k]
        return d

    def html(self):
        print '''
<!doctype html>
<html>
  <head>
    <title>XML Summary: %(count)s Files</title>
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
      .elements {
        display: none;
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
  <h1>XML Summary: %(count)s Files</h1>
  <ul class="namespaces">
''' % {"count": c(self.doc_count)}
        for ns in keys(self.s):
            count = self.count(ns)
            print '  <li>'
            print '    <span class="glyphicon glyphicon-plus"></span>'
            print '    <span class="namespace">%s</span>' % ns
            print '    <span class="count">%s</span>' % c(count)
            print '    <ul class="elements">'
            for tag in keys(self.s[ns]):
                if ns == "http://www.tei-c.org/ns/1.0":
                    a = '<a href="http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-%s.html">&lt;%s&gt;</a>' % (tag, tag)
                else:
                    a = '&lt;%s&gt;' % tag
                count = self.count(ns, tag)
                print '      <li>'
                print '        <span class="glyphicon glyphicon-plus"></span>'
                print '        <span class="element">%s</span>'% a
                print '        <span class="count">%s</span>' % c(count)
                print '        <ul class="attributes">'
                for attribute in keys(self.s[ns][tag]):
                    count = self.count(ns, tag, attribute)
                    print '          <li>'
                    print '            <span class="attribute">%s</span>' % attribute
                    print '            <span class="count">%s</span>' % c(count)
                    #for value in keys(self.s[ns][tag][attribute]):
                    #    count = self.s[ns][tag][attribute]['___count']
                    #    if count < 2: 
                    #        continue
                    print '          </li>'
                print '          </li>'
                print '        </ul>'
            print '      </li>'
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
      $(this).parent().children("ul").each(function(i, ul) {
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

def keys(d):
    keys = d.keys()
    if '___count' in keys:
        keys.pop(keys.index('___count'))
    keys.sort(lambda a, b: cmp(d[b]['___count'], d[a]['___count']))
    return keys

def c(n):
    "1234 -> 1,234"
    return format(n, ",d")

def icon(n, state):
    if n > 0:
        if state == 'closed':
            return '<span class="glyphicon glyphicon-plus"></span>'
        else:
            return '<span class="glyphicon glyphicon-minus"></span>'
    else:
        return ''

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


if __name__ == "__main__":
    main()
