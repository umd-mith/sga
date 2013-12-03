# # Data Management
# This file contains Backbone models and collections.
# Also, supplies logic for populating models and collections 
# when a JSONLD manifest comes all in one file.

SGASharedCanvas.Data = SGASharedCanvas.Data or {}

( ->

  # This stores a textual file that is target of
  # textual annotations (e.g. a TEI file in SGA).
  class TextFile extends Backbone.Model
    idAttribute : "target"
    url : (u) ->
      return @get "target"
    # We override sync, since the data to be fetched is not JSON
    sync : (method, model, options) ->
      if method == 'read'
        Backbone.ajax
          url: @url()
          method: 'GET'
          dataType: 'xml'
          success: (data) =>
            @set
              data : data.documentElement.textContent
            @trigger "sync"
          error: (e) -> 
            throw new Error "Could not load text data."
      else
        # Call the default sync method for other sync methods
        Backbone.Model.prototype.sync.apply @, args...

  # The following models are populated directly from the manifest
  # Eventually they will populated in a restful way.

  # idAttribute is used to map JSONLD @id to Backbone id  

  class Sequence extends Backbone.Model
    idAttribute : "@id"

  class Range extends Backbone.Model
    idAttribute : "@id"

  class Layer extends Backbone.Model
    idAttribute : "@id"

  class Content extends Backbone.Model
    idAttribute : "@id"

  class Zone extends Backbone.Model
    idAttribute : "@id"  

  class Annotation extends Backbone.Model
    idAttribute : "@id"

  class Image extends Backbone.Model
    idAttribute : "@id"

  # This model is populated with data from other models
  class ParsedAnno extends Backbone.Model
    0

  ## COLLECTIONS ##

  class TextFiles extends Backbone.Collection
    model: TextFile

  class Manifests extends Backbone.Collection
    model: Manifest

  class Sequences extends Backbone.Collection
    model: Sequence

  class Ranges extends Backbone.Collection
    model: Range

  class Layers extends Backbone.Collection
    model: Layer

  class Zones extends Backbone.Collection
    model: Zone

  class Canvases extends Backbone.Collection
    model: Canvas

  class Annotations extends Backbone.Collection
    model: Annotation

  class Images extends Backbone.Collection
    model: Image

  class Contents extends Backbone.Collection
    model: Content

  class ParsedAnnos extends Backbone.Collection
    model: ParsedAnno

  ## NESTED MODELS

  class Manifest extends Backbone.Model
    idAttribute : "url"
    # Using initialize instead of defaults for nested collections
    # is recommended by the Backbone FAQs:
    # http://documentcloud.github.io/backbone/#FAQ-nested
    initialize : ->
      @sequences = new Sequences
      @ranges = new Ranges
      @canvases = new Canvases      
      @textFiles = new TextFiles

  class Canvas extends Backbone.Model
    idAttribute : "@id"
    initialize: ->
      @contents  = new Contents
      @images    = new Images
      @zones     = new Zones
      @SGAannos  = new Annotations
      @textItems = new ParsedAnnos

  # Start a general manifest collection
  SGASharedCanvas.Data.Manifests = manifests = new Manifests

  ## Code for importing from one JSONLD file

  importFromURL = (manifest) ->
    
    $.ajax
      url: manifest.get "url"
      type: 'GET'
      contentType: 'application/json'
      processData: false
      dataType: 'json'
      #beforeSend: (jqXHR) ->
      #  jqXHR.setRequestHeader 'Accept-Encoding', 'gzip,deflate'
      success: (data) ->
        importJSONLD data, manifest
        manifest.trigger "sync"
      error: (e) -> 
        throw new Error "Could not load the manifest"

  importJSONLD = (jsonld, manifest) ->

    graph = jsonld["@graph"]

    # This is temporary until the JSONLD is better organized
    id_graph = {}

    for node in graph
      id_graph[node["@id"]] = node if node["@id"]?              

    manifest.set
      raw_graph : id_graph

    for id, node of id_graph

      # Organize nodes by type
      if node["@type"]? 
        types = node["@type"]
        types = [ types ] if !$.isArray types
        
        if "sc:Manifest" in types
          manifest.set node

        if "sc:Sequence" in types
          sequence = new Sequence
          manifest.sequences.add sequence

          canvases = [node["first"]]

          next_node = node
          while next_node?
            rest = next_node["rdf:rest"]
            rest = [ rest ] if !$.isArray rest
            next = rest[0]["@id"]
            next_node = id_graph[next]
            canvases.push next_node["first"] if next_node?

          sequence.set 
            "@id"      : node["@id"]
            "@type"    : node["@type"]
            "label"    : node["label"]
            "canvases" : canvases

        else if "sc:Range" in types
          range = new Range
          manifest.ranges.add range

          ranges.set node

        else if "sc:Canvas" in types
          canvas = new Canvas
          manifest.canvases.add canvas

          canvas.set node

  SGASharedCanvas.Data.importFullJSONLD = (url) ->
    if url?
      manifest = manifests.get(url)
      if !manifest?
        manifest = new Manifest
        manifest.set 
          url: url
        manifests.add manifest   
        importFromURL manifest
        manifest
      else
        manifest
    else
      throw new Error "Could not load the manifest"

  SGASharedCanvas.Data.importCanvasData = (n, cb) ->

    makeArray = (item) ->
      if !$.isArray item then [ item ] else item

    extractSpatialConstraint = (model, id) ->
      return unless id?
      constraint = graph[id]
      if 'oa:FragmentSelector' in makeArray(constraint["@type"])
        if constraint["value"].substr(0,5) == "xywh="
          model.set
            shape : "Rectangle"
          bits = constraint["value"].substr(5).split(",")
          model.set
            x      : parseInt(bits[0],10)
            y      : parseInt(bits[1],10)
            width  : parseInt(bits[2],10)
            height : parseInt(bits[3],10)
      else
        if constraint["beginOffset"]?
          model.set
            beginOffset : parseInt constraint["beginOffset"]
        if constraint["endOffset"]?
          model.set 
            endOffset : parseInt constraint["endOffset"]
      # TODO: handle other shape constraints (rectangles, ellipses)
      # TODO: handle music notation constraints
      # TODO: handle time constraints for video/sound annotations

    extractTextTarget = (model, id) ->
      return unless id?
      target = graph[id]
      if "oa:SpecificResource" in makeArray(target["@type"])
        model.set
          target : target["full"]
        if target["oa:hasStyle"]?
          styleItem = graph[target["oa:hasStyle"]["@id"]]
          if "text/css" in styleItem["format"]
            content.set
              css : styleItem["chars"]
        if target["oa:hasClass"]?
          content.set
            cssclass : target["oa:hasClass"]
        extractSpatialConstraint model, target["selector"]
      else
        model.set
          target : id

    extractTextBody = (model, id) ->
      return unless id?
      body = graph[id]
      #textSource.addFile(body.oahasSource)
      model.set
        source : body["full"]
      extractSpatialConstraint model, body["selector"]

    # Get everything for n
    getCanvasAnnos = ->      

      canvases = manifest.sequences.first().get "canvases"

      n = canvases.length if n > canvases.length

      canvas_id = canvases[n-1]

      # Locate current canvas Backbone object
      canvas =  manifest.canvases.get canvas_id

      # Only load annotations the first time
      if canvas.contents.length <= 0

        for id, node of graph

          if node["@type"]? 
            types = makeArray node["@type"]

            target = node["on"]
            body = node["resource"]

            # Get content annotations
            if "sc:ContentAnnotation" in types and graph[target]["full"] == canvas_id
              content = new Content
              canvas.contents.add content

              extractTextTarget content, target
              extractTextBody content, body

            # Get zones - *N.B. there are no zones in SGA*
            else if "sc:ZoneAnnotation" in types and graph[target]["full"] == canvas_id
              zone = new Zone
              canvas.zones.add zone

              extractSpatialConstraint zone, target
              zone.set node

            # Get images
            else if "oa:Annotation" in types and node["@id"] in manifest.get("images") and target == canvas_id
              image = new Image
              canvas.images.add image
              image.set graph[node["resource"]]

            # Get everything else (including project-specific annotations!) for this canvas
            # Could this be moved into its own project-specific module at some point?
            else 
              sgaTypes = (f.substr(4) for f in types when f.substr(0,4) == "sga:" and f.substr(f.length-10) == "Annotation")
              if sgaTypes.length > 0
                sources = []
                canvas.contents.forEach (c,i) ->
                  s = c.get("source")
                  if s? and s not in sources
                    sources.push s
                
                # filter annotations and store only those relevant to the current canvas
                if graph[target]["full"] in sources
                  annotation = new Annotation
                  canvas.SGAannos.add annotation

                  extractTextTarget annotation, target
                  annotation.set 
                    "@id"   : node["@id"]
                    "@type" : node["@type"]

        # Now deal with highlights.
        # Each addition, deletion, etc., targets a scContentAnnotation
        # but we want to make sure we get any scContentAnnotation text
        # that isn't covered by any of the other annotations

        # This is inspired by NROFF as implemented, for example, in
        # [the Discworld mud.](https://github.com/Yuffster/discworld_distribution_mudlib/blob/master/obj/handlers/nroff.c)
        # It also has shades of a SAX processor thrown in.

        items = []
        modstart = {}
        modend = {}
        modInfo = {}
        setMod = (item) ->
          indent = item.get "indent"
          align = item.get "align"
          source = item.get "target"
          start = item.get "beginOffset"
          end = item.get "endOffset"
          id = item.get "id"
          modInfo[id] = item
          modstart[source] ?= {}
          modstart[source][start] ?= []
          modstart[source][start].push id
          modend[source] ?= {}
          modend[source][end] ?= []
          modend[source][end].push id

        canvas.SGAannos.forEach (anno, i) ->
          setMod anno

        sources = (s for s of modstart)
        loadedSources = manifest.textFiles

        for source in sources
          do (source) ->

          # Store once the annotated text resource (TEI in SGA)
          loaded = loadedSources.where({target : target}).length > 0

          if not loaded
            s = new TextFile
            loadedSources.add s
            s.set 
             target : source
            s.fetch()

            s.once 'sync', ->

              text = s.get("data")

              # Split annotations according to their start/end offsets to avoid overlap
              modIds = []
              br_pushed = false

              pushTextItem = (classes, css, target, start, end, indent=null, aling=null) ->
                titem = new ParsedAnno
                titem.set 
                  type: classes
                  css: css.join(" ")
                  text: text[start ... end]
                  id: source + "-" + start + "-" + end
                  target: target
                  start: start
                  end: end
                if indent? then titem.set {indent : indent}
                if align? then titem.set {align : align}
                canvas.textItems.add titem                
              
              processNode = (start, end) ->
                classes = []
                css = []
                for id in modIds
                  classes.push modInfo[id].get "@type"
                  cssClass = modInfo[id].get "cssclass"
                  if cssClass? then classes.push cssClass
                  annocss = modInfo[id].get "css"
                  if $.isArray(annocss)
                    css.push annocss.join(" ")
                  else
                    css.push annocss

                classes.push "Text" if classes.length == 0

                makeTextItems start, end, classes, css

              #
              # We run through each possible shared canvas
              # target that might be mapped onto the source TEI
              # via the TextContent annotation. We want to target
              # the shared canvas text content zone, not the
              # text source that the highlight is targeting in the
              # actual open annotation model.
              #
              makeTextItems = (start, end, classes, css, indent, align) ->
                canvas.contents.forEach (c,i) ->
                  beginOffset = c.get "beginOffset"
                  endOffset = c.get "endOffset"
                  if start <= endOffset and end >= beginOffset
                    st = Math.min(Math.max(start, beginOffset), endOffset)
                    en = Math.max(Math.min(end, endOffset), beginOffset)
                    pushTextItem classes, css, c.get("source"), st, en, indent, align
                false

              #
              # A line break is just a zero-width annotation at
              # the given position.
              #
              makeLinebreak = (pos, indent, align) ->
                classes = [ "LineBreak" ]
                #classes.push modInfo[id].type for id in modIds
                makeTextItems pos, pos, classes, [ "" ], indent, align

              #
              mstarts = modstart[source] || []
              mends = modend[source] || []
              last_pos = 0
              positions = (parseInt(p,10) for p of mstarts).concat(parseInt(p,10) for p of mends).sort (a,b) -> a-b
              for pos in positions
                if pos != last_pos
                  processNode last_pos, pos
                  if br_pushed and !text.substr(last_pos, pos - last_pos).match(/^\s*$/)
                    br_pushed = false
                  needs_br = false
                  for id in (mstarts[pos] || [])
                    if "sga:LineAnnotation" in modInfo[id].get "@type"
                      needs_br = true
                    modIds.push id
                  for id in (mends[pos] || [])
                    if "sga:LineAnnotation" in modInfo[id].get "@type"
                      needs_br = true
                    idx = modIds.indexOf id
                    modIds.splice idx, 1 if idx > -1
                  if needs_br and not br_pushed
                    indent = null
                    align = null
                    if modInfo[id].indent? then indent = modInfo[id].get "indent"
                    if modInfo[id].align? then align = modInfo[id].get "align"
                    makeLinebreak pos, indent, align
                    br_pushed = true
                  last_pos = pos
              processNode last_pos, text.length

              canvas.trigger 'sync'

      canvas.on 'sync', ->
        cb canvas if cb?

    # If the manifest has already been loaded, go ahead and load the canvas
    # otherwise, wait and listen.
    #
    # **N.B. For now, we assume that there is only one manifest**
    #
    manifest = manifests.first()
    if manifest?
      graph = manifest.get "raw_graph"
      getCanvasAnnos() 
    else
      manifests.once "add", ->        
        manifest = this.first()
        manifest.once "sync", ->
          graph = manifest.get "raw_graph"
          getCanvasAnnos() 
)()