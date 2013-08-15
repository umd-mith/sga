# coding=UTF-8
from flask import jsonify, request, make_response, abort, render_template, url_for, json
from sga_search import sga_search, annotator, crossdomain

import solr, urllib2, ast, uuid, re

# Notes
# Use request.args for GET and request.form for POST.
# Use render_template(...) to override error messages with templates (or just return """<html>""", ERROR)

sga_search.jinja_env.globals['static'] = (
    lambda filename: url_for('static', filename=filename))

@sga_search.route('/')
@sga_search.route('/index')
def index():
    return """<!DOCTYPE html><html><head><title>SGA Search manager</title><p>Hic sunt leones.

    <ul>
        <li><a href="annotate?q=text:feelings">Test annotation</a>
        <li><a href="manifest?m=http://sga.mith.org/sc-demo/ox-ms_abinger_c56/Manifest.json&q=text:feelings">Test manifest + query</a>
    </ul>

    """

@sga_search.route('/search', methods = ['GET'])
@crossdomain.crossdomain(origin='*')
def search():
    
    def do_search(s, f, q):

        fields = f.split(",")
        fqs = []
        if len(fields) > 0:
            fqs = fields[1:]
            fqs = [f+":"+q for f in fqs]

        response = s.raw_query(q=fields[0]+":"+q, 
            fl='shelfmark,id', 
            fq=fqs, 
            wt='json', 
            rows='9999', 
            hl='true', 
            hl_fl="text", 
            hl_fragsize='0',
            hl_simple_pre='___',
            hl_simple_post='___')
        r = json.loads(response)
        results = {"numFound": r["response"]["numFound"], "results":[]}

        for res_orig in r["response"]["docs"]:
            res = res_orig.copy()
            ident = res["id"]
            hl = " ".join(r["highlighting"][ident]["text"][0].replace(u"\u2038", u"").replace(u"\u2014", u"").split())
            fragsize = 100
            matches = [[m.start(),m.end()] for m in re.finditer(r'___.*?___', hl)]
            res["hls"] = []
            for m in matches:
                before = len(hl[:m[0]])
                match = len(q)
                after = len(hl[m[1]:])                

                total = fragsize
                total -= len(q)

                left = m[0]
                right = m[1]

                while total > 0:
                    if left > 0:
                        left-=1
                        total-=1
                    if right < len(hl):
                        right+=1
                        total-=1
                    
                hl_text = re.sub(r'___(.*?)___', r'<em>\1</em>', hl[left:right])
                res["hls"].append(hl_text)
            
            results["results"].append(res)

        return jsonify(results)



    if len(request.args)==2 and "f" in request.args and "q" in request.args:
        
        s = solr.SolrConnection("http://localhost:8080/solr/sga")

        # try:
        s.conn.connect()
        return do_search(s, request.args["f"], request.args["q"])
        # except:
        #     abort(500)

    else:
        abort(400)   


@sga_search.route('/annotate', methods = ['GET'])
@crossdomain.crossdomain(origin='*')
def annotate():
    
    def do_annotation(s, query):
        # This will probably stay hardcoded
        TEI_data = "http://sga.mith.org/sc-demo/tei/ox/"

        # Create a UUID for this iteration
        uid = str(uuid.uuid4())

        field_s = query.split(':')[0]
        fields = field_s.split(',')
        q = query.split(':')[1]

        annotations = []

        short = ""
        for f in fields:
            if f == 'added':
                short='add_pos'
            elif f == 'deleted':
                short='del_pos'
            elif f == 'hand_mws':
                short='mws_pos'
            elif f == 'hand_pbs':
                short='pbs_pos'
            elif f == 'hand_comp':
                short='comp_pos'

            if f != 'text':
                response = s.raw_query(q=f+":"+q, fl=f+','+short, wt='json', rows='9999', hl='true', hl_fl=f, hl_fragsize='0')
                r = json.loads(response)
                annotations += annotator.do_hacky_things(f, short, r, TEI_data)

            else:
                response = s.query(f+":"+q, fields=f, highlight=True, hl_fragsize='0', rows='9999')
                for i, TEI_id in enumerate(response.highlighting):
                    hl = response.highlighting[TEI_id][f][0]
                    annotations += [m for m in annotator.oa_annotations(f, hl, TEI_id, TEI_data, uid+":-"+str(i))]

        final = {}
        for anno in annotations:
            for a in anno:
                final[a] = anno[a]

        return jsonify(final)

    if len(request.args)==1 and "q" in request.args:
        
        s = solr.SolrConnection("http://localhost:8080/solr/sga")

        try:
            s.conn.connect()
            return do_annotation(s, request.args["q"])
        except:
            abort(500)

    else:
        abort(400)    

@sga_search.route('/manifest', methods = ['GET'])
@crossdomain.crossdomain(origin='*')
def manifest():
    """DEPRECATED"""
    # Check parameters and return JSON
    if len(request.args)==2 and "m" and "q" in request.args:
        # Check parameters' well-formedness at this level
        try:
            manifest_string = urllib2.urlopen(request.args["m"])
            manifest = ast.literal_eval("".join(manifest_string))

            # Create a UUID for this iteration
            uid = str(uuid.uuid4())

            resource = { "http://www.openarchives.org/ore/terms/isDescribedBy" : [ { "type" : "bnode" ,
                        "value" : "http://localhost:5000/annotate?q="+request.args["q"]
                    }],
                    "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" : [ { "type" : "uri" ,
                            "value" : "http://www.openarchives.org/ore/terms/Aggregation"
                        }, 
                        { "type" : "uri" ,
                            "value" : "http://www.w3.org/1999/02/22-rdf-syntax-ns#List"
                        }, 
                        { "type" : "uri" ,
                            "value" : "http://www.shared-canvas.org/ns/TextAnnotationList"
                        }]
                    }

            ext_URL = { "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" : [ { "type" : "uri" ,
                            "value" : "http://www.openarchives.org/ore/terms/ResourceMap"
                            }]
                        }

            aggr = [ { "type" : "bnode" , "value" : "_:"+uid }]

            # Add aggregation to manifest's already existing description
            manifest[request.args["m"]]["http://www.openarchives.org/ore/terms/aggregates"] = aggr

            # Add resource and external URL to the manifest at root level
            manifest["_:"+uid] = resource
            manifest["http://localhost:5000/annotate?q="+request.args["q"]] = ext_URL

            return jsonify(manifest)

        except:
            abort(500)
    else:
        abort(400)

@sga_search.route('/demo', methods = ['GET'])
@crossdomain.crossdomain(origin='*')
def demo():
    request.args
    return render_template("demo.html")