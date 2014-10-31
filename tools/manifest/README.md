# manifest

manifest.py is a Python 2/3 library for generating a Shared Canvas manifest from
Shelley-Godwin TEI for use by the Shared Canvas viewer. It's also a work 
in progress...

## Setup

    pip install requirements.txt

## Run

    ./manifest.py /path/to/tei/file.xml > manifest.jsonld

## Test

    py.test test.py
