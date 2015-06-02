#!/usr/bin/env python

"""
A script to add foliation attributes to Prometheus Unbound surfaces based on
CSV input data.
"""

import csv
import os
import os.path
import re

TEI_PATH = '../../data/tei/ox/'
E1 = 'ox-ms_shelley_e1'
E2 = 'ox-ms_shelley_e2'
E3 = 'ox-ms_shelley_e3'


def add_foliation_to(ms):
    ms_path = "{0}{1}/".format(TEI_PATH, ms)
    with open('input/e1-foliation.csv', 'rU') as csvfile:
        reader = csv.reader(csvfile, delimiter=";")
        for row in reader:
            seq_no = row[0][-8:-4]
            # Locate PU file
            tei_file = "{0}{1}-{2}.xml".format(ms_path, ms, seq_no)
            if os.path.isfile(tei_file):
                folio = re.sub(r'\s+', ' ', row[3].strip())
                shelfmark = re.sub(r'\s+', ' ', row[9].strip())
                # print folio, shelfmark
                with open(tei_file, 'rU') as tei_xml:
                    cntnt = tei_xml.read()
                    # get rid of existing attributes, if present
                    cntnt = re.sub(r'mith:shelfmark="[^"]+"', "", cntnt, re.M)
                    cntnt = re.sub(r'mith:folio="[^"]+"', "", cntnt, re.M)

                    folio_att = 'mith:folio="{0}"'.format(folio)
                    folio_shelfmark = 'mith:shelfmark="{0}"'.format(shelfmark)
                    # Add new attributes
                    repl_str = r"\1 {0} {1}>".format(folio_att, folio_shelfmark)
                    cntnt = re.sub(r"(<surface[^>]+)>", repl_str, cntnt, re.M)
                with open(tei_file, 'w') as tei_xml:
                    tei_xml.write(cntnt)
            else:
                print "not found: " + tei_file


def main():
    add_foliation_to(E1)
    add_foliation_to(E2)
    add_foliation_to(E3)

if __name__ == "__main__":
    main()
