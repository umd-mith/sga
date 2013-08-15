# coding=UTF-8
from flask import jsonify
import re, uuid

def do_hacky_things(f, short, response, source_dir):
    docs = response["response"]["docs"]
    hls = response["highlighting"]

    annotations = []

    def make_anno(uid, start, end, source_dir, TEI_id):
        anno = { "_:" + uid : 
                    { "http://www.w3.org/ns/openannotation/core/hasTarget" : [ { "type" : "bnode" ,
                        "value" : "_:"+uid+":-hT"
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

        target = {"_:"+uid+":-hT" : 
                    { "http://www.w3.org/ns/openannotation/core/hasSource" : [ { "type" : "uri" ,
                        "value" : source_dir + TEI_id + ".xml"
                    }],
                    "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" : [ { "type" : "uri" ,
                        "value" : "http://www.w3.org/ns/openannotation/core/SpecificResource"
                    }] ,
                        "http://www.w3.org/ns/openannotation/core/hasSelector" : [ { "type" : "bnode" ,
                            "value" : "_:"+uid+":-hS"
                        }]
                    }
                }

        selector = {"_:"+uid+":-hS" : { 
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

        return [anno, target, selector]

    for TEI_id in hls:

        for hl in hls[TEI_id][f]:

            for i, m in enumerate(re.finditer(r'([^<]*)<em>([^<]+)</em>([^<]*)', hl)):
                full_m = m.group(1)+m.group(2)+m.group(3)
                match_len = len(m.group(2))
                for d in docs:
                    if full_m == d[f]:
                        start = d[short][0].split(":")[0]
                        end = int(start)+match_len

                        uid = str(uuid.uuid4())
                        annotations += make_anno(uid, start, end, source_dir, TEI_id)
                    for i, df in enumerate(d[f]):
                        if full_m == df:
                            start = d[short][i].split(":")[0]
                            end = int(start)+match_len

                            uid = str(uuid.uuid4())

                            annotations += make_anno(uid, start, end, source_dir, TEI_id)

    return annotations


def oa_annotations(f, hl, TEI_id, source_dir, uid):
    """ This function returns an ao:Annotation for highlighted text """
    
    for i, m in enumerate(re.finditer(r'<em>([^<]+)</em>', hl)):
        cur_hl = len(m.group(1))
        start = m.start()
        end = start + (cur_hl)

        anno = { "_:" + uid : 
                    { "http://www.w3.org/ns/openannotation/core/hasTarget" : [ { "type" : "bnode" ,
                        "value" : "_:"+uid+":-hT"
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
        target = {"_:"+uid+":-hT" : 
                    { "http://www.w3.org/ns/openannotation/core/hasSource" : [ { "type" : "uri" ,
                        "value" : source_dir + TEI_id + ".xml"
                    }],
                    "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" : [ { "type" : "uri" ,
                        "value" : "http://www.w3.org/ns/openannotation/core/SpecificResource"
                    }] ,
                        "http://www.w3.org/ns/openannotation/core/hasSelector" : [ { "type" : "bnode" ,
                            "value" : "_:"+uid+":-hS"
                        }]
                    }
                }
        selector = {"_:"+uid+":-hS" : { 
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

        return anno, target, selector

def TEI_positions (hl, TEI_id, source_dir):
    """ This function finds the positions of highlighted text in a *raw* TEI file """

    def replace_entities (text):
        # Use dictionary to replace with real characters
        # entities = {"&#x2038;" : "‸",
        #             "&#x2014;" : "—"
        #             }
        # for e in entities:
        #     text = text.replace(e, entities[e])

        # Or just replace any entity with 1 character (?)
        text = re.sub(r'\&[^;]+;', r'?', text)

        return text

    # Fetch TEI file, clean up entities
    source = file(source_dir+TEI_id+".xml", "r")
    TEI = source.read()
    source.close()
    TEI = replace_entities(TEI)

    # Find positions of highlighted text excluding markers

    start_size = 4
    end_size = 5

    hl_pos = []

    for i, m in enumerate(re.finditer(r'<em>([^<]+)</em>', hl)):
        cur_hl = len(m.group(1))
        start = m.start() - (start_size + end_size) * i
        end = start + (cur_hl)
        # Add 1 to make up for positions starting 0 when mapping to TEI
        hl_pos.append((start+1, end+1, cur_hl, m.group(1)))

    # Find highlighted text in source TEI

    TEI_hl = []

    text_count = 0
    is_text = False
    for n, c in enumerate(TEI):

        if c == "<": is_text = False

        if is_text:
            text_count += 1
            for i, hl in enumerate(hl_pos):
                if text_count == hl[0]:
                    TEI_hl.append({"term": TEI[n:n+hl[2]], "values" : [n, n+hl[2]]})

        if n+1 != len(TEI) and c == ">" and TEI[n-1] != '?' and TEI[n+1] != '<': is_text = True

    # Return positions
    return TEI_hl