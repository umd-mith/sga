# sga

[![Build Status](https://travis-ci.org/umd-mith/sga.svg)](http://travis-ci.org/umd-mith/sga)

sga is a Python 2/3 module for generating a Shared Canvas manifest from
Shelley-Godwin TEI for use by the Shared Canvas viewer. It's also a work 
in progress...

## Setup

    python setup.py install

## Command Line

When you install you will get a command line program `tei2sc` which you 
can pass the path to a TEI file and the URI you'd like to use for the 
manifest, and it will print out a Shared Canvas document as JSON-LD:

    tei2sc /path/to/tei.xml http://example.com/manifest.jsonld > manifest.jsonld

##  As a Library

```python

from sga.shared_canvas import Manifest

m = Manifest("/path/to/a/tei/file.xml")
print m.jsonld()
```

## Test

    py.test test.py
