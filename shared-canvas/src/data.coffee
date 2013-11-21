# # Data Management
# This file contains Backbone models and collections.
# Also, supplies logic for populating models and collections 
# when a JSONLD manifest comes all in one file.

SGASharedCanvas.Data = SGASharedCanvas.Data or {}

( ->

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

  ## COLLECTIONS ##

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

  class Canvas extends Backbone.Model
    idAttribute : "@id"
    initialize: ->
      @contents = new Contents
      @images   = new Images
      @zones    = new Zones
      @SGAannos = new Annotations

  # Start a general manifest collection
  manifests = new Manifests

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

    manifest.trigger("sync")

    #console.log manifest

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

  SGASharedCanvas.Data.importCanvasData = (n) ->

    makeArray = (item) ->
      if !$.isArray item then [ item ] else item

    extractSpatialConstraint = (model, id) ->
      return unless id?
      constraint = graph[id]
      if 'oa:FragmentSelector' in makeArray(constraint.type)
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
            beginOffset : parseInt constraint["endOffset"]
      # TODO: handle other shape constraints (rectangles, ellipses)
      # TODO: handle music notation constraints
      # TODO: handle time constraints for video/sound annotations

    extractTextTarget = (model, id) ->
      return unless id?
      target = graph[id]
      if "oa:SpecificResource" in makeArray(target["@type"])
        model.set
          target : target["oa:hasSource"]
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

            # Get everything else (including project-specific annotations!)
            # Could this be moved into its own project-specific module at some point?
            else 
              sgaTypes = (f.substr(4) for f in types when f.substr(0,4) == "sga:" and f.substr(f.length-10) == "Annotation")
              if sgaTypes.length > 0
                annotation = new Annotation
                canvas.SGAannos.add annotation

                extractTextTarget annotation, target                
                annotation.set 
                  "@id"   : node["@id"]
                  "@type" : node["@type"]

      console.log manifest    

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
