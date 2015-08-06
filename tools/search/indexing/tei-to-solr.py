#! /usr/bin/env python
# coding=UTF-8
""" Index fields from SGA TEI to a Solr instance"""

import os, sys, re, string
import solr
import xml.sax, json
from xml.etree import ElementTree as etree
from six.moves.urllib.parse import urljoin

TEI  =  'http://www.tei-c.org/ns/1.0'
MITH =  'http://mith.umd.edu/sc/ns1#'
XML  =  'http://www.w3.org/XML/1998/namespace'
XI   =  'http://www.w3.org/2001/XInclude'

class TeiData :
    def __init__(self, path_to_tei):

        # Connect to solr instance
        s = solr.SolrConnection('http://localhost:8080/solr/sga')
        ns = {'tei': TEI, 'xi': XI, 'xml': XML}

        tei = etree.parse(path_to_tei).getroot()

        # First get metadata that will need to be added to each solr doc 
        # (There is one solr doc per surface)   

        root_viewer_url = "http://shelleygodwinarchive.org/sc/"
        preserve_titles = ["ms_shelley", "prometheus_unbound"]

        tei_id = tei.get('{%s}id' % XML)
        esc_title_id = tei_id

        for i, title in enumerate(preserve_titles):
            esc_title_id = esc_title_id.replace(title, '{#title'+str(i)+"#}")

        esc_title_id = re.sub(r'[-_]', '/', esc_title_id)

        base_viewer_url = re.sub(
                            r'\{#title(\d+)#\}',
                            lambda m: preserve_titles[int(m.group(1))],
                            esc_title_id)
        base_viewer_url = base_viewer_url.replace("ox/", "oxford/")        

        self.base_viewer_url = root_viewer_url + base_viewer_url
        self.authors = tei.find('.//{%(tei)s}msItem[@class="#work"]/{%(tei)s}bibl/{%(tei)s}author' % ns).text
        self.attribution = tei.find('.//{%(tei)s}repository' % ns).text
        self.shelfmark = tei.find('.//{%(tei)s}idno' % ns).text

        sole_hand = tei.find('.//{%(tei)s}handNote[@scope="sole"]' % ns)
        major_hand = tei.find('.//{%(tei)s}handNote[@scope="major"]' % ns)
        if sole_hand is None:
            self.default_hand = major_hand.get('{%s}id' % XML)
        else:
            self.default_hand = sole_hand.get('{%s}id' % XML)

        # Get information about location of works
        self.works = []
        self.work_loci = {}
        for work in tei.findall('.//{%(tei)s}msItem[@class="#work"]' % ns):
            w_title = work.find('./{%(tei)s}bibl/{%(tei)s}title' % ns).text
            w_title = w_title.strip()
            w_title = w_title.lower()
            w_title = re.sub(r"["+string.punctuation+r"\s]", "_", w_title)
            self.works.append(w_title)
            for locus in work.findall('.//{%(tei)s}locus' % ns):
                if locus.attrib.get('target'):
                    targets = re.split(r'\s+', locus.attrib.get('target').strip())
                    for target in targets:
                        target = target.lstrip("#")
                        self.work_loci[target] = w_title


        # load each surface document
        for i, inc in enumerate(tei.findall('.//{%(tei)s}sourceDoc/{%(xi)s}include' % ns)):
            filename = urljoin(path_to_tei, inc.attrib['href'])
            self.position = str(i+1)

            source = open(filename)
            xml.sax.parse(source, GSAContentHandler(s, self, filename))
            source.close()
 
class SurfaceDoc :
    def __init__(self, 
        solr="", 
        shelfmark="",
        shelf_label="",
        viewer_url="",
        authors="",
        attribution="",
        doc_id=None,
        has_figure=False, 
        text="", 
        hands={"mws":"","pbs":"", "comp":"", "library":""},
        works={}, 
        mod={"add":[],"del":[]}, 
        hands_pos={"mws":[], "pbs":[], "comp":[], "library":[]}, 
        hands_tei_pos={"mws":[], "pbs":[], "comp":[], "library":[]},
        mod_pos={"add":[],"del":[]}):
      
        # Solr connection
        self.solr = solr

        # General fields
        self.shelfmark = shelfmark
        self.doc_id = doc_id

        # Text and positions
        # TODO: determine hand fields from source TEI - they are dynamic fields in Solr. 
        # Do the same with their positions.
        self.text = text
        self.hands = hands
        self.works = works
        self.mod = mod
        self.hands_pos = hands_pos
        self.hands_tei_pos = hands_tei_pos
        self.mod_pos = mod_pos
        self.has_figure = has_figure


    def commit(self):
        # print "id: %s\nshelf: %s\ntext: %s\nhands: %s\nmod: %s\nhands_pos: %s\nmod_pos: %s\n" % (self.doc_id, self.shelfmark, self.text, self.hands, self.mod, self.hands_pos, self.mod_pos)

        paras = {"id" : self.doc_id, 
                "shelfmark" : self.shelfmark, 
                "shelf_label" : self.shelf_label,
                "viewer_url" : self.viewer_url,
                # "work" : self.work,
                "authors" : self.authors,
                "attribution" : self.attribution,
                "text" : self.text, 
                "hand_mws" : self.hands["mws"], 
                "hand_pbs" : self.hands["pbs"], 
                "hand_comp" : self.hands["comp"],
                "hand_library" : self.hands["library"], 
                "added" : self.mod["add"], 
                "deleted" : self.mod["del"],
                "mws_pos" : self.hands_pos["mws"], 
                "pbs_pos" : self.hands_pos["pbs"],
                "comp_pos" : self.hands_pos["comp"],
                "library_pos" : self.hands_pos["library"],
                "add_pos" : self.mod_pos["add"], 
                "del_pos" : self.mod_pos["del"],
                "has_figure" : self.has_figure}

        for w in self.works:
            key = "work_" + w
            paras[key] = self.works[w]

        self.solr.add_many([paras])
        self.solr.commit()

class GSAContentHandler(xml.sax.ContentHandler):
    def __init__(self, s, tei_data, filename):
        xml.sax.ContentHandler.__init__(self)

        self.solr = s
        self.tei_data = tei_data
        self.pos = 0
        self.hands = [tei_data.default_hand]        
        self.latest_hand = self.hands[-1]
        self.hand_start = 0
        self.path = [] # name, hand

        self.addSpan = {"id": "", "hand": None}
        self.delSpan = None
        self.milestone = None
        self.cur_work = []

        self.handShift = False

        self.filename = filename

        self.works = {}
        for work in self.tei_data.works:
            self.works[work] = ""

        # Initialize doc
        self.doc = SurfaceDoc(solr = self.solr, works=self.works)

        print self.doc
        #purge 
        self.doc.shelfmark=""
        shelf_label=""
        viewer_url = ""
        authors=""
        attribution=""
        self.doc.doc_id=None
        self.doc.text=""
        self.doc.hands={"mws":"","pbs":"", "comp":"", "library":""}
        for work in self.tei_data.works:
            self.doc.works[work] = ""
        self.doc.mod={"add":[],"del":[]}
        self.doc.hands_pos={"mws":[], "pbs":[], "comp":[], "library":[]}
        self.doc.hands_tei_pos={"mws":[], "pbs":[], "comp":[], "library":[]}
        self.doc.mod_pos={"add":[],"del":[]}
 
    def startElement(self, name, attrs):
        # add element to path stack
        self.path.append([name, self.hands[-1]])

        def _is_in_work(xmlid):
            if self.tei_data:
                if xmlid:
                    xmlid = xmlid.strip()
                    if xmlid in self.tei_data.work_loci.keys():
                        return self.tei_data.work_loci[xmlid]
                else:
                    return False

        if name == "surface":
            if "partOf" in attrs:
                partOf = attrs["partOf"] if "partOf" in attrs else " "
                # self.doc.shelfmark = partOf[1:] if partOf[0] == "#" else partOf
            self.doc.doc_id = attrs["xml:id"]

            # Add metadata

            self.doc.shelf_label = attrs["mith:shelfmark"]+", "+attrs["mith:folio"]
            self.doc.viewer_url = self.tei_data.base_viewer_url + "#/p" + self.tei_data.position
            
            self.doc.authors = self.tei_data.authors
            self.doc.attribution = self.tei_data.attribution
            self.doc.shelfmark = self.tei_data.shelfmark

            work = _is_in_work(attrs["xml:id"])    
            print "surface:", work, attrs["xml:id"]        
            if work:
                if len(self.cur_work) == 0:
                    self.cur_work.append(work)
                elif self.cur_work[-1] != work:
                    self.cur_work.append(work)

        if name == "zone":
            if attrs.get("type") == "sketch":
                self.doc.has_figure = True

        if name == "line":
            if attrs.get("xml:id"):
                work = _is_in_work(attrs["xml:id"])
                print "line:", work, attrs["xml:id"]
                if work:
                    if len(self.cur_work) == 0:
                        self.cur_work.append(work)
                    elif self.cur_work[-1] != work:
                        self.cur_work.append(work)

        if name == "milestone":
            if attrs.get('unit') == 'tei:seg' and attrs.get("xml:id"):
                work = _is_in_work(attrs["xml:id"])
                if work:
                    self.milestone = attrs["spanTo"][1:]
                    self.doc.work = work
                    if len(self.cur_work) == 0:
                        self.cur_work.append(work)
                    elif self.cur_work[-1] != work:
                        self.cur_work.append(work)

        if "hand" in attrs:
            hand = attrs["hand"]
            if hand[0]=="#": hand = hand[1:]
            self.hands.append(hand)
            self.path[-1][-1] = hand

        if "type" in attrs:
            if attrs["type"] == "library":
                hand = "library"
                self.hands.append(hand)
                self.path[-1][-1] = hand

        # Create a new added section
        if name == "add" or name == 'addSpan':
            self.doc.mod["add"].append("")            
            self.doc.mod_pos["add"].append(str(self.pos)+":") 
        if name == "del" or name == 'delSpan':
            self.doc.mod["del"].append("")
            self.doc.mod_pos["del"].append(str(self.pos)+":")

        if name == "addSpan":
            spanTo = attrs["spanTo"] if "spanTo" in attrs else " "
            self.addSpan["id"] = spanTo[1:] if spanTo[0] == "#" else spanTo
            if "hand" in attrs:
                self.addSpan["hand"] = attrs["hand"]

        if name == "delSpan":
            spanTo = attrs["spanTo"] if "spanTo" in attrs else " "
            self.delSpan = spanTo[1:] if spanTo[0] == "#" else spanTo

        # if this is the anchor of and (add|del)Span, close the addition/deletion
        if name == "anchor":
            if "xml:id" in attrs:
                if attrs["xml:id"] == self.addSpan:

                    # If the anchor corresponds to and addSpan with @hand, remove the hand from stack
                    if self.addSpan["hand"] != None:
                        if len(self.path) > 1 and self.hands[-1] != self.path[-2][-1]:
                            self.hands.pop()
                    # reset addSpan
                    self.addSpan["id"] = ""
                    self.addSpan["hand"] = None
                    self.doc.mod_pos["add"][-1] += str(self.pos)
                if attrs["xml:id"] == self.delSpan:
                    self.delSpan = None
                    self.doc.mod_pos["del"][-1] += str(self.pos)
                if attrs["xml:id"] == self.milestone:
                    self.milestone = None
                    if len(self.cur_work) > 1:
                        self.cur_work.pop()

        if name == "handShift":
            if "new" in attrs:
                self.handShift = True
                hand = attrs["new"]
                if hand[0]=="#": hand = hand[1:]
                self.hands.append(hand)
                self.path[-1][-1] = hand

                # print self.hands, self.path

 
    def endElement(self, name):
        # Remove hand from hand stack if this is the last element with that hand
        # Unless it's an addSpan with hand, in which case we defer to the corresponding anchor
        # Here we are assuming that there is only one handShift per page.
        if not self.handShift and name != "addSpan" and self.addSpan["hand"] == None:
            if len(self.path) > 1 and self.hands[-1] != self.path[-2][-1]:
                self.hands.pop()

        ### SPECIAL CASES ###
        if self.doc.doc_id == "ox-ms_abinger_c58-0057" and self.path[-1][-1] == "mws":
            # self.hands.pop()
            self.hands.append("pbs")
                
        # Remove the element from element stack
        self.path.pop()

        if name == "line":
            if len(self.cur_work) > 1:
                self.cur_work.pop()

        if name == "surface":
            self.doc.end = self.pos
            self.doc.commit()

            print "**** end of file" 

        if name == "add":
             self.doc.mod_pos["add"][-1] += str(self.pos)

        if name == "del":
             self.doc.mod_pos["del"][-1] += str(self.pos)

 
    def characters(self, content):
        # Has the hand changed? If yes, write positions and keep track of new starting point
        if self.latest_hand != self.hands[-1]:
            # Add extra space between hand occurences (will need to consider this when mapping to positions)
            self.doc.hands[self.latest_hand] += " "
            self.doc.hands_pos[self.latest_hand].append(str(self.hand_start)+":"+str(self.pos))
            self.latest_hand = self.hands[-1]
            self.hand_start = self.pos + 1

        # if this is a descendant of add|del or we are in an (add|del)Span area, add content to added/deleted
        elements = [e[0] for e in self.path]
        if 'add' in elements or self.addSpan["id"] != "":
            self.doc.mod["add"][-1] += content
        if 'del' in elements or self.delSpan:
            self.doc.mod["del"][-1] += content

        # Add text to current hand and to full-text field
        self.doc.hands[self.hands[-1]] += content
        # if a work has been identified, add content
        if len(self.cur_work) > 0:
            self.doc.works[self.cur_work[-1]] += content
        self.doc.text += content

        # Update current position
        self.pos += len(content)
 
if __name__ == "__main__":

    if len(sys.argv) != 2:
        print 'Usage: ./tei-to-solr.py path_to_tei'
        sys.exit(1)    

    TeiData(sys.argv[1])
