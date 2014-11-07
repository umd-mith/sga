# sga

[![Build Status](https://travis-ci.org/umd-mith/sga.svg)](http://travis-ci.org/umd-mith/sga)

sga is a Python 2/3 module for generating a Shared Canvas manifest from
Shelley-Godwin TEI for use by the Shared Canvas viewer. It's also a work 
in progress...

## Setup

    pip install requirements.txt

## Use

```python

from sga.shared_canvas import Manifest

m = Manifest("/path/to/a/tei/file.xml")
print m.jsonld()
```

## Test

    py.test test.py
