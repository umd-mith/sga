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

  class Canvas extends Backbone.Model
    idAttribute : "@id"

  class Annotation extends Backbone.Model
    idAttribute : "@id"

  class LayerAnnotation extends Annotation
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

  # # MANIFEST MODEL
  # Each Manifest model groups other collections.

  class Manifest extends Backbone.Model
    idAttribute : "url"
    defaults:
      "sequences" : new Sequences()
      "ranges"    : new Ranges()
      "layers"    : new Layers()
      "zones"     : new Zones()
      "canvases"  : new Canvases()

  # Start a general manifest collection
  manifests = new Manifests()


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
        throw new Error("Could not load the manifest")

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
        types = [ types ] if !$.isArray(types)
        
        # Get and store data
        if "sc:Sequence" in types
          sequence = new Sequence()
          manifest.get("sequences").add sequence

          canvases = [node["first"]]

          next_node = node
          while next_node?
            rest = next_node["rdf:rest"]
            rest = [ rest ] if !$.isArray(rest)
            next = rest[0]["@id"]
            next_node = id_graph[next]
            canvases.push next_node["first"] if next_node?

          sequence.set 
            "@id"      : node["@id"]
            "@type"    : node["@type"]
            "label"    : node["label"]
            "canvases" : canvases

        else if "sc:Range" in types
          range = new Range()
          manifest.get("ranges").add range

          ranges.set node

        else if "sc:Layer" in types
          layer = new Layer()
          manifest.get("layers").add layer

          layer.set node

        else if "sc:Zone" in types
          zone = new Zone()
          manifest.get("zones").add zone

          zone.set node

        else if "sc:Canvas" in types
          canvas = new Canvas()
          manifest.get("canvases").add canvas

          canvas.set node

    manifest.trigger("sync")

    # SGASharedCanvas.Data = collections

    #console.log manifest

  SGASharedCanvas.Data.importFullJSONLD = (url) ->
    if url?
      manifest = manifests.get(url)
      if !manifest?
        manifest = new Manifest()
        manifest.set 
          url: url
        manifests.add manifest   
        importFromURL manifest
        manifest
      else
        manifest
    else
      # Throw exception
      0

  SGASharedCanvas.Data.importCanvasData = (n) ->
    #
    # For now, we assume that there is only one manifest 
    #
    manifests.once "add", ->
      manifest = this.first()   

      manifest.once "sync", ->
        # Now get everything for n
        graph = manifest.get("raw_graph")

        canvases = manifest.get("sequences").first().get("canvases")

        n = canvases.length if n > canvases.length

        canvas = canvases[n-1]

        #canvasObj = manifest.get("canvases").get(canvas)

        #console.log canvasObj

        for id, node of graph

          if node["sc:forMotivation"]?
            if node["sc:forMotivation"]["@id"] == "sga:source"

              next_node = node
              while next_node?
                if graph[graph[next_node["first"]]["first"]]["on"] == canvas
                  console.log graph[graph[next_node["first"]]["first"]]
                  break
                rest = next_node["rdf:rest"]
                rest = [ rest ] if !$.isArray(rest)
                next = rest[0]["@id"]
                next_node = graph[next]

          # if node["@type"]? 
          #   types = node["@type"]
          #   types = [ types ] if !$.isArray(types)

          #   if "oa:Annotation" in types and node["on"] == canvas
          #     console.log node["resource"], node["@id"]

)()
