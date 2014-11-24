# # Data Management
# This file contains Backbone models and collections.
# Also, supplies logic for populating models and collections 
# when a JSONLD manifest comes all in one file.

SGASharedCanvas.Data = SGASharedCanvas.Data or {}

( ->

  ## GENERAL MODELS ##

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

  class Zone extends Backbone.Model
    idAttribute : "@id"

  class Annotation extends Backbone.Model
    idAttribute : "@id"

  class Image extends Backbone.Model
    idAttribute : "@id"

  # This model is populated with data from other models
  class ParsedAnno extends Backbone.Model
    0

  ## GENERAL COLLECTIONS ##

  class TextFiles extends Backbone.Collection
    model: TextFile

  class Sequences extends Backbone.Collection
    model: Sequence

  class Ranges extends Backbone.Collection
    model: Range

  class Layers extends Backbone.Collection
    model: Layer

  class Zones extends Backbone.Collection
    model: Zone

  class Annotations extends Backbone.Collection
    model: Annotation

  class Images extends Backbone.Collection
    model: Image

  class ParsedAnnos extends Backbone.Collection
    model: ParsedAnno

  ## MANIFESTS ##

  class Manifest extends Backbone.Model
    idAttribute : "url"

    # Using initialize instead of defaults for nested collections
    # is recommended by the Backbone FAQs:
    # http://documentcloud.github.io/backbone/#FAQ-nested
    initialize : ->
      @sequences = new Sequences
      @ranges = new Ranges
      @canvasesMeta = new CanvasesMeta
      @canvasesData = new CanvasesData
      @textFiles = new TextFiles

    url : (u) ->
      return @get "url"

    # We override sync, since we want to re-organize some of the JSON data
    sync : (method, model, options) ->
      if method == 'read'
        Backbone.ajax
          url: @url()
          type: 'GET'
          contentType: 'application/json'
          processData: false
          dataType: 'json'
          #beforeSend: (jqXHR) ->
          #  jqXHR.setRequestHeader 'Accept-Encoding', 'gzip,deflate'
          success: (data) =>
            importManifest data, @
            @trigger 'sync'
          error: (e) ->
            throw new Error "Could not load the manifest"
      else
        # Call the default sync method for other sync methods
        Backbone.Model.prototype.sync.apply @, args...

  class Manifests extends Backbone.Collection
    model: Manifest

  ## CANVASES ##

  class CanvasMeta extends Backbone.Model
    idAttribute : "@id"

  class CanvasesMeta extends Backbone.Collection
    model: CanvasMeta

  class CanvasData extends Backbone.Model
    idAttribute : "@id"
    initialize: ->
      @contents  = new Contents
      @images    = new Images
      @zones     = new Zones
      @SGAannos  = new Annotations

    # We override fetch, since we actually fetch and re-organize
    # data from the parent Manifest model
    fetch : (manifest) ->
      importCanvas @, manifest

  class CanvasesData extends Backbone.Collection
    model: CanvasData
    # BackBone's reset() removes model silently. 
    # We want it to tell its models that they're going to die
    # (so that their views know that they need to go too)
    reset: (models=[], options={}) ->

      for model in @models
        @_removeReference model
        # trigger the remove event for the model manually
        model.trigger('remove', model, @)

      @_reset()
      @add @models, _.extend({silent: true}, options)
      if !options.silent
        @trigger 'reset', @, options
      @

  ## CONTENTS ##

  class Content extends Backbone.Model
    idAttribute : "@id"
    initialize: ->
      @textItems = new ParsedAnnos

  class Contents extends Backbone.Collection
    model: Content

  # Expose manifest collection
  SGASharedCanvas.Data.Manifests = new Manifests

  ## METHODS FOR LOADING AND PROCESSING DATA

  importManifest = (jsonld, manifest) ->
    # This method imports manifest level data and metadata

    graph = jsonld["@graph"]

    # This is temporary until the JSONLD is better organized
    id_graph = {}

    for node in graph
      id_graph[node["@id"]] = node if node["@id"]?

    # Store the full manifest for further processing at canvas level
    manifest.set
      raw_graph : id_graph

    for id, node of id_graph

      # Organize nodes by type
      if node["@type"]?
        types = node["@type"]
        types = [ types ] if !$.isArray types
        
        if "sc:Manifest" in types
          manifest.set node
          images = []
          for image in node["sc:hasImageAnnotations"]
            images.push image
          manifest.set "images", images

        if "sc:Sequence" in types
          canvases = [node["first"]]
          canvases = canvases.concat node["rest"]

          manifest.sequences.add
            "@id"      : node["@id"]
            "@type"    : node["@type"]
            "label"    : node["label"]
            "canvases" : canvases

        else if "sc:Range" in types
          manifest.ranges.add node

        else if "sc:Canvas" in types
          manifest.canvasesMeta.add node

  importCanvas = (canvas, manifest) ->
    # This method imports manifest level data and metadata   
   
    extractSpatialConstraint = (model, id) ->
      return unless id?
      constraint = graph[id]
      if 'oa:FragmentSelector' in SGASharedCanvas.Utils.makeArray(constraint["@type"])
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
      if "oa:SpecificResource" in SGASharedCanvas.Utils.makeArray(target["@type"])
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

    # Main code for importCanvas()

    canvas_id = canvas.get "id"
    graph = manifest.get "raw_graph"

    # First get generic canvas metadata. This is up for grabs without looping on the graph
    canvas.set graph[canvas_id]
    # Signal that the basic canvas data is loaded.
    # Further on there will be another event 'fullsync'
    # that signals that subcollections have been loaded too.
    canvas.trigger 'sync'

    # Don't process annos again if the canvas is already populated.
    if canvas.contents.length <= 0

      # find content annotations right away. You'll need these before creating parsing other annos
      for id, node of graph

        if node["@type"]?
          types = SGASharedCanvas.Utils.makeArray node["@type"]

          target = node["on"]
          body = node["resource"]

          # Get content annotations
          if "sc:ContentAnnotation" in types and graph[target]["full"] == canvas_id
            content = new Content
            content.set graph[id]

            extractTextTarget content, target
            extractTextBody content, body

            # Adding triggers the view. Alternatively, we could have the view listen to change,
            # but we trigger change too often by setting attributes gradually. 
            # We could store attributes in an object and set them all together.
            canvas.contents.add content

          # Get zones - *N.B. there are no zones in SGA*
          else if "sc:ZoneAnnotation" in types and graph[target]["full"] == canvas_id
            zone = new Zone
            canvas.zones.add zone

            extractSpatialConstraint zone, target
            zone.set node

      for id, node of graph

        if node["@type"]?
          types = SGASharedCanvas.Utils.makeArray node["@type"]

          target = node["on"]
          body = node["resource"]

          # Get images
          if "oa:Annotation" in types and node["@id"] in manifest.get("images") and target == canvas_id
            image = new Image
            image.set graph[node["resource"]]

            # Adding triggers the view. Alternatively, we could have the view listen to change,
            # but we trigger change too often by setting attributes gradually. 
            # We could store attributes in an object and set them all together.
            canvas.images.add image

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
        id = item.get "@id"
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

            pushTextItem = (classes, css, contentAnno, start, end, indent=null, aling=null) ->
              titem = new ParsedAnno
              titem.set
                type: classes
                css: css.join(" ")
                text: text[start ... end]
                id: source + "-" + start + "-" + end
                target: contentAnno.get("@id")
                start: start
                end: end
              if indent? then titem.set {indent : indent}
              if align? then titem.set {align : align}
              contentAnno.textItems.add titem
            
            processNode = (start, end) ->
              classes = []
              css = []
              for id in modIds
                for t in SGASharedCanvas.Utils.makeArray modInfo[id].get "@type"
                  classes.push t.replace(":", "")
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
                  pushTextItem classes, css, c, st, en, indent, align
              false

            #
            # A line break is just a zero-width annotation at
            # the given position.
            #
            makeLinebreak = (pos, indent, align) ->
              classes = [ "LineBreak" ]
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
                  if modInfo[id].get("indent")? then indent = modInfo[id].get "indent"
                  if modInfo[id].get("align")? then align = modInfo[id].get "align"
                  makeLinebreak pos, indent, align
                  br_pushed = true
                last_pos = pos
            processNode last_pos, text.length

      canvas.trigger 'fullsync'

)()
