#! /usr/bin/env python
# coding=UTF-8
""" Index fields from SGA TEI to a Solr instance"""

import os, sys
import solr
import xml.sax
 
class Doc :
    def __init__(self, 
        solr="", 
        shelfmark="", 
        doc_id=None, 
        text="", 
        hands={"mws":"","pbs":"", "comp":""}, 
        mod={"add":[],"del":[]}, 
        hands_pos={"mws":[], "pbs":[], "comp":[]}, 
        hands_tei_pos={"mws":[], "pbs":[], "comp":[]},
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
        self.mod = mod
        self.hands_pos = hands_pos
        self.hands_tei_pos = hands_tei_pos
        self.mod_pos = mod_pos


    def commit(self):
        print "id: %s\nshelf: %s\ntext: %s\nhands: %s\nmod: %s\nhands_pos: %s\nmod_pos: %s\n" % (self.doc_id, self.shelfmark, self.text, self.hands, self.mod, self.hands_pos, self.mod_pos)
        self.solr.add(id=self.doc_id, 
            shelfmark=self.shelfmark, 
            text=self.text, 
            hand_mws=self.hands["mws"], 
            hand_pbs=self.hands["pbs"], 
            hand_comp=self.hands["comp"],
            added=self.mod["add"], 
            deleted=self.mod["del"],
            mws_pos=self.hands_pos["mws"], 
            pbs_pos=self.hands_pos["pbs"],
            comp_pos=self.hands_pos["comp"],
            add_pos=self.mod_pos["add"], 
            del_pos=self.mod_pos["del"])
        self.solr.commit()

class GSAContentHandler(xml.sax.ContentHandler):
    def __init__(self, s):
        xml.sax.ContentHandler.__init__(self)

        self.solr = s
        self.pos = 0
        self.hands = ["mws"]        
        self.latest_hand = self.hands[-1]
        self.hand_start = 0
        self.path = [] # name, hand

        self.addSpan = None
        self.delSpan = None

        # Initialize doc
        self.doc = Doc(
            solr = self.solr)

        print self.doc
        #purge 
        self.doc.shelfmark=""
        self.doc.doc_id=None
        self.doc.text=""
        self.doc.hands={"mws":"","pbs":"", "comp":""}
        self.doc.mod={"add":[],"del":[]}
        self.doc.hands_pos={"mws":[], "pbs":[], "comp":[]}
        self.doc.hands_tei_pos={"mws":[], "pbs":[], "comp":[]}
        self.doc.mod_pos={"add":[],"del":[]}
        # print self.doc.mod["add"]
 
    def startElement(self, name, attrs):
        # add element to path stack
        self.path.append([name, self.hands[-1]])

        if name == "surface":
            partOf = attrs["partOf"] if "partOf" in attrs else " "
            self.doc.shelfmark = partOf[1:] if partOf[0] == "#" else partOf
            self.doc.doc_id = attrs["xml:id"]

        if "hand" in attrs:
            hand = attrs["hand"]
            if hand[0]=="#": hand = hand[1:]
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
            self.addSpan = spanTo[1:] if spanTo[0] == "#" else spanTo

        if name == "delSpan":
            spanTo = attrs["spanTo"] if "spanTo" in attrs else " "
            self.delSpan = spanTo[1:] if spanTo[0] == "#" else spanTo

        # if this is the anchor of and (add|del)Span, close the addition/deletion
        if name == "anchor":
            if attrs["xml:id"] == self.addSpan:
                self.addSpan = None
                self.doc.mod_pos["add"][-1] += str(self.pos)
            if attrs["xml:id"] == self.delSpan:
                self.delSpan = None
                self.doc.mod_pos["del"][-1] += str(self.pos)
 
    def endElement(self, name):
        # Remove hand from hand stack if this is the last element with that hand    
        if len(self.path) > 1 and self.hands[-1] != self.path[-2][-1]:
            self.hands.pop()
        # Remove the element from element stack
        self.path.pop()

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
        if 'add' in elements or self.addSpan:
            self.doc.mod["add"][-1] += content
        if 'del' in elements or self.delSpan:
            self.doc.mod["del"][-1] += content

        # Add text to current hand and to full-text field
        self.doc.hands[self.hands[-1]] += content
        self.doc.text += content

        # Update current position
        self.pos += len(content)
 
if __name__ == "__main__":

    if len(sys.argv) != 2:
        print 'Usage: ./tei-to-solr.py path'
        sys.exit(1)

    # Connect to solr instance
    s = solr.SolrConnection('http://localhost:8080/solr/sga')

    # Walk provided directory for xml files; parse them and create/commit documents
    xml_dir = os.path.normpath(sys.argv[1]) + os.sep
    for f in os.listdir(xml_dir):
        if f.endswith('.xml'):
            source = open(xml_dir + f)
            xml.sax.parse(source, GSAContentHandler(s))
            source.close()