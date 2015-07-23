# coding=UTF-8
from flask import jsonify
import re, uuid

def oa_annotations(hl, TEI_id, source_dir, uid, hl_simple_pre, hl_simple_post, serialize):
  """ This function returns an ao:Annotation for highlighted text """
  
  TEI_subdir = TEI_id[0:-5] + '/'

  annos = []
  # A field can contain multiple highlights; loop on them and add the resulting
  # annotations to annos.
  for i, m in enumerate(re.finditer(hl_simple_pre+r'(.+?)'+hl_simple_post, hl)):
    markers_len = len(hl_simple_pre) + len(hl_simple_post)
    cur_hl = len(m.group(1))
    
    # Start and end positions should be understood by SC: 
    # the solr text field has all the white spaces but not the XML tags.
    # We need to exclude highglight markers from count.
    start = m.start() - (markers_len * i)
    end = start + (cur_hl)

    if serialize == "jsonld":
      anno = { "@id" : "_:"+uid+"-"+str(i),
        "@type" : ["oax:Highlight", "oa:Annotation", "sga:SearchAnnotation"],
        "on" : "_:"+uid+"-"+str(i)+":-hT"
      }

      target = { "@id" : "_:"+uid+"-"+str(i)+":-hT",
        "@type" : "oa:SpecificResource",
        "selector" : "_:"+uid+"-"+str(i)+":-hS",
        "full" : source_dir + TEI_subdir + TEI_id + ".xml"
      }
        
      selector = { "@id" : "_:"+uid+"-"+str(i)+":-hS",
        "@type" : "textOffsetSelector",
        "beginOffset": start,
        "endOffset": end
      }

    else:
      anno = { "_:"+uid+"-"+str(i) : 
                { "http://www.w3.org/ns/openannotation/core/hasTarget" : [ { "type" : "bnode" ,
                  "value" : "_:"+uid+"-"+str(i)+":-hT"
                }],
                "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" : [ { "type" : "uri" ,
                      "value" : "http://www.w3.org/ns/openannotation/core/Annotation"
                    }, 
                    { "type" : "uri" ,
                      "value" : "http://www.w3.org/ns/openannotation/extension/Highlight"
                    }, 
                    { "type" : "uri" ,
                      "value" : "http://www.shelleygodwinarchive.org/ns1#SearchAnnotation"
                    }]
                }
              }
      target = {"_:"+uid+"-"+str(i)+":-hT" : 
                { "http://www.w3.org/ns/openannotation/core/hasSource" : [ { "type" : "uri" ,
                  "value" : source_dir + TEI_subdir + TEI_id + ".xml"
                }],
                "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" : [ { "type" : "uri" ,
                  "value" : "http://www.w3.org/ns/openannotation/core/SpecificResource"
                }] ,
                  "http://www.w3.org/ns/openannotation/core/hasSelector" : [ { "type" : "bnode" ,
                    "value" : "_:"+uid+"-"+str(i)+":-hS"
                  }]
                }
              }
      selector = {"_:"+uid+"-"+str(i)+":-hS" : { 
                    "http://www.w3.org/ns/openannotation/extension/begin" : [ { 
                      "type" : "literal" ,
                      "value" : start ,
                      "datatype" : "http://www.w3.org/2001/XMLSchema#integer"
                    }
                     ] ,
                    "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" : [ { 
                      "type" : "uri" ,
                      "value" : "http://www.w3.org/ns/openannotation/extension/TextOffsetSelector"
                    }
                     ] ,
                    "http://www.w3.org/ns/openannotation/extension/end" : [ { 
                      "type" : "literal" ,
                      "value" : end ,
                      "datatype" : "http://www.w3.org/2001/XMLSchema#integer"
                    }
                     ]
                  }}

    annos += [anno, target, selector]

  return annos
