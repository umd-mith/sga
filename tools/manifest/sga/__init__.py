from .shared_canvas import Manifest

def jsonld(tei_file):
    m = Manifest(tei_file)
    return m.jsonld()

