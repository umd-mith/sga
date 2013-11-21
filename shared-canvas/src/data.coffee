# # Data Management
# This file contains Backbone models and collections.
# Also, supplies logic for populating models and collections 
# when a JSONLD manifest comes all in one file.

SGASharedCanvas.Data = SGASharedCanvas.Data or {}

( () ->

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

  class CanvasAnnotation extends Annotation
    0

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

  class CanvasAnnos extends Backbone.Collection
    model: CanvasAnnotation

  ## NESTED MODELS

  # # MANIFEST MODEL
  # Each Manifest model groups other collections.

  class Manifest extends Backbone.Model
    idAttribute : "url"
    # Using initialize instead of defaults for nested collections
    # is recommended by the Backbone FAQs:
    # http://documentcloud.github.io/backbone/#FAQ-nested
    initialize : () ->
      @sequences = new Sequences
      @ranges = new Ranges
      @layers = new Layers
      @zones = new Zones
      @canvases = new Canvases

  # # CANVAS MODEL
  # Each Canvas model groups its own annotations,
  # which are populated when a canvas is visited

  class Canvas extends Backbone.Model
    idAttribute : "@id"
    initialize: () ->
      @annotations = new CanvasAnnos

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
        
        # Get and store data
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

        else if "sc:Layer" in types
          layer = new Layer
          manifest.layers.add layer

          layer.set node

        else if "sc:Zone" in types
          zone = new Zone
          manifest.zones.add zone

          zone.set node

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

    # Get everything for n
    getCanvasAnnos = () ->
      graph = manifest.get "raw_graph"

      canvases = manifest.sequences.first().get "canvases"

      n = canvases.length if n > canvases.length

      canvas_id = canvases[n-1]

      # Locate current canvas Backbone object
      canvas =  manifest.canvases.get canvas_id

      # Only load annotations the first time
      if canvas.annotations.length <= 0

        resource = null

        for id, node of graph

          if node["sc:forMotivation"]?["@id"] == "sga:source"

              next_node = node
              while next_node?
                if graph[graph[next_node["first"]]["first"]]["on"] == canvas_id
                  resource = graph[graph[next_node["first"]]["first"]]["resource"]
                  break
                rest = next_node["rdf:rest"]
                rest = [ rest ] if !$.isArray(rest)
                next = rest[0]["@id"]
                next_node = graph[next]

              break

        # Finally get all the canvas annotations
        for id, node of graph

          if node["on"]?

            target = graph[node["on"]]

            if target["full"]? and target["full"] == resource

              # Create new CanvasAnnotation
              canvasAnnotation = new CanvasAnnotation
              canvas.annotations.add canvasAnnotation

              # Resolve resources and selectors
              copy_node = node

              selector = graph[target["selector"]]
              target["selector"] = 
                start : selector["beginOffset"]
                end : selector["endOffset"]
              copy_node["on"] = target["full"]
              copy_node["selector"] = target["selector"]
              canvasAnnotation.set copy_node

      console.log manifest    

    # If the manifest has already be loaded, go ahead and load the canvas
    # otherwise, wait and listen.
    #
    # **N.B. For now, we assume that there is only one manifest**
    #
    manifest = manifests.first()
    if manifest?
      getCanvasAnnos() 
    else
      manifests.once "add", ->        
        manifest = this.first()
        manifest.once "sync", ->
          getCanvasAnnos() 
)()
