# # Data Managment
SGAReader.namespace "Data", (Data) ->
  
  #
  # ## Data.Manifest
  #
  Data.namespace "Manifest", (Manifest) ->

    # 
    # Here we define all the Backbone models and collections.
    # They are instantiated and populated when importing JSONLD
    #

    ## MODELS ##
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

    Manifest.initInstance = (args...) ->
      MITHgrid.initInstance "SGA.Reader.Data.Manifest", args..., (that) ->
        options = that.options

        loadedUrls = []

        importFromURL = (url, cb) ->
          if url in loadedUrls
            cb()
            return
          loadedUrls.push url
          that.addItemsToProcess 1
          
          $.ajax
            url: url
            type: 'GET'
            contentType: 'application/json'
            processData: false
            dataType: 'json'
            #beforeSend: (jqXHR) ->
            #  jqXHR.setRequestHeader 'Accept-Encoding', 'gzip,deflate'
            success: (data) ->
              that.importJSON data, cb
            error: (e) -> 
              throw new Error("Could not load the manifest")


        # Expose properties and methods

        that.importJSON = (json, cb) ->
          # we care about certain namespaces - others we ignore
          # those we care about, we store as Backbone collections 
          # {nsPrefix}{localName}

          graph = json["@graph"]

          # Initialize Collections
          collections = 
            sequences : new Sequences()
            ranges : new Ranges()
            layers : new Layers()
            zones : new Zones()
            canvases : new Canvases()

          # This is temporary until the JSONLD is better organized
          id_graph = {}

          for node in graph
            if node["@id"]?
              id_graph[node["@id"]] = node

          for id, node of id_graph

            # Organize nodes by type
            if node["@type"]? 
              types = node["@type"]
              types = [ types ] if !$.isArray(types)
              
              # Get and store data
              if "sc:Sequence" in types
                sequence = new Sequence()
                collections.sequences.add sequence

                canvases = [node["first"]]

                next_node = node
                while next_node?
                  rest = next_node["rdf:rest"]
                  rest = [ rest ] if !$.isArray(rest)
                  next = rest[0]["@id"]
                  next_node = id_graph[next]
                  if next_node?
                    canvases.push next_node["first"]

                sequence.set 
                  "@id"      : node["@id"]
                  "@type"    : node["@type"]
                  "label"    : node["label"]
                  "canvases" : canvases

              else if "sc:Range" in types
                range = new Range()
                collections.ranges.add range

                ranges.set node

              else if "sc:Layer" in types
                layer = new Layer()
                collections.layers.add layer

                layer.set node

              else if "sc:Zone" in types
                zone = new Zone()
                collections.zones.add zone

                zone.set node

              else if "sc:Canvas" in types
                canvas = new Canvas()
                collections.canvases.add canvas

                canvas.set node
          
          console.log collections

        that.importFromURL = (url, cb) ->
          importFromURL url, ->
            cb() if cb?
