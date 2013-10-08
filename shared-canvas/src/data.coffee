# # Data Managment
SGAReader.namespace "Data", (Data) ->

  #
  # ## Data.StyleStore
  #

  Data.namespace "StyleStore", (StyleStore) ->
    StyleStore.initInstance = (args...) ->
      MITHgrid.initInstance args..., (that) ->
        options = that.options

        docs = { }
        regex = new RegExp("(?:\\.(\\S+)\\s*\\{\\s*([^}]*)\\s*\\})", "mg")

        #
        # Associates the CSS content with the given id.
        #
        that.addStyles = (id, css) ->
          return if docs[id]?
          docs[id] = { }
          results = regex.exec(css)
          while results?.index?
            docs[id][results[1]] = results[2]
            results = regex.exec(css)

        #
        # Returns the CSS style rules for a given class as defined by the
        # CSS content associated with the given id.
        #
        that.getStylesForClass = (id, klass) ->
          if docs[id]?[klass]?
            docs[id][klass]
          else
            ""

  #
  # ## Data.TextStore
  #
  Data.namespace "TextStore", (TextStore) ->
    TextStore.initInstance = (args...) ->
      MITHgrid.initInstance args..., (that) ->
        options = that.options

        fileContents = { }
        loadingFiles = { }
        pendingFiles = { }

        that.addFile = (files) ->
          files = [ files ] unless $.isArray(files)
          for file in files 
            do (file) ->
              if file? and !fileContents[file]? and !loadingFiles[file]?
                loadingFiles[file] = [ ]
                $.ajax
                  url: file
                  type: 'GET'
                  processData: false
                  success: (data) ->
                    c = data.documentElement.textContent
                    fileContents[file] = c
                    f(c) for f in loadingFiles[file]
                    delete loadingFiles[file]

        that.withFile = (file, cb) ->
          if fileContents[file]?
            cb(fileContents[file])
          else if loadingFiles[file]?
            loadingFiles[file].push cb
          else
            that.addFile file
            loadingFiles[file].push cb

  #
  # ## Data.Manifest
  #
  Data.namespace "Manifest", (Manifest) ->

    #
    # We list all of the namespaces that we care about and the prefix
    # we map them to. Some of the namespaces are easy "misspellings"
    # that let us support older namespaces.
    #
    NS =
      "http://dms.stanford.edu/ns/": "sc"
      "http://www.shared-canvas.org/ns/": "sc"
      "http://www.w3.org/2000/01/rdf-schema#": "rdfs"
      "http://www.w3.org/1999/02/22-rdf-syntax-ns#": "rdf"
      "http://www.w3.org/2003/12/exif/ns#": "exif"
      "http://purl.org/dc/elements/1.1/": "dc"
      "http://www.w3.org/ns/openannotation/core/": "oa"
      "http://www.openannotation.org/ns/": "oa"
      "http://www.w3.org/ns/openannotation/extension/": "oax"
      "http://www.openarchives.org/ore/terms/": "ore"
      "http://www.shelleygodwinarchive.org/ns/1#": "sga"
      "http://www.shelleygodwinarchive.org/ns1#": "sga"
      "http://www.w3.org/2011/content#": "cnt"
      "http://purl.org/dc/dcmitype/": "dctypes"

    types =
      "http://www.w3.org/1999/02/22-rdf-syntax-ns#type": "item"
      "http://www.w3.org/ns/openannotation/core/hasMotivation": "item"

    Manifest.initInstance = (args...) ->
      MITHgrid.initInstance "SGA.Reader.Data.Manifest", args..., (that) ->
        options = that.options

        data = MITHgrid.Data.Store.initInstance()

        that.size = -> data.size()
        
        importer = MITHgrid.Data.Importer.RDF_JSON.initInstance data, NS, types

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
            contentType: 'application/rdf+json'
            processData: false
            dataType: 'json'
            success: (data) ->
              that.addItemsProcessed 1
              that.importJSON data, cb
            error: (e) -> 
              that.addItemsProcessed 1
              throw new Error("Could not load the manifest")

        # we want to get the rdf/JSON version of things if we can
        that.importJSON = (json, cb) ->
          # we care about certain namespaces - others we ignore
          # those we care about, we translate for datastore
          # {nsPrefix}{localName}
          syncer = MITHgrid.initSynchronizer cb
          syncer.increment()
          importer.import json, (ids) ->
            #
            # If the manifest indicates that another document describes
            # this resource, then we load the data before continuing
            # processing for this resource.
            #
 
            # we want anything that has the oreisDescribedBy property
            idset = MITHgrid.Data.Set.initInstance ids
            urls = data.getObjectsUnion(idset, 'oreisDescribedBy')
            
            urls.visit (url) ->
              syncer.increment()
              importFromURL url, syncer.decrement
            syncer.decrement()
          syncer.done()

        itemsWithType = (type) ->
          type = [ type ] if !$.isArray(type)
          types = MITHgrid.Data.Set.initInstance type
          data.getSubjectsUnion(types, "type").items()

        itemsForCanvas = (canvas) ->
          # Given a canvas, find the TEI XML URL
          canvas = [ canvas ] if !$.isArray(canvas)
          canvasSet = MITHgrid.Data.Set.initInstance(canvas)
          specificResources = data.getSubjectsUnion(canvasSet, "oahasSource")
          imageAnnotations = data.getSubjectsUnion(canvasSet, "oahasTarget")            
          contentAnnotations = data.getSubjectsUnion(specificResources, "oahasTarget")
          tei = data.getObjectsUnion(contentAnnotations, 'oahasBody')
          teiURL = data.getObjectsUnion(tei, 'oahasSource')

          # Now find all annotations targeting that XML URL
          specificResourcesAnnos = data.getSubjectsUnion(teiURL, 'oahasSource')
          annos = data.getSubjectsUnion(specificResourcesAnnos, 'oahasTarget').items()

          # Append other annotations collected so far and return
          return annos.concat imageAnnotations.items(), contentAnnotations.items()

        flushSearchResults = ->
          types = MITHgrid.Data.Set.initInstance ['sgaSearchAnnotation']
          searchResults = data.getSubjectsUnion(types, "type").items()
          data.removeItems searchResults

        getSearchResultCanvases = ->
          types = MITHgrid.Data.Set.initInstance ['sgaSearchAnnotation']
          searchResults = data.getSubjectsUnion(types, "type")
          specificResources = data.getObjectsUnion(searchResults, "oahasTarget") 
          teiURL = data.getObjectsUnion(specificResources, 'oahasSource')

          sources = data.getSubjectsUnion(teiURL, 'oahasSource')
          
          annos = data.getSubjectsUnion(sources, 'oahasBody')
          step = data.getObjectsUnion(annos, 'oahasTarget')
          canvasKeys = data.getObjectsUnion(step, 'oahasSource')

          return $.unique(canvasKeys.items())


        #
        # Get things of different types. For example, "scCanvas" gets
        # all of the canvas items.
        #
        that.getCanvases    = -> itemsWithType 'scCanvas'
        that.getZones       = -> itemsWithType 'scZone'
        that.getSequences   = -> itemsWithType 'scSequence'
        that.getAnnotations = -> itemsWithType 'oaAnnotation'
        that.getRanges      = -> itemsWithType 'scRange'
        that.getAnnotationsForCanvas = itemsForCanvas
        that.flushSearchResults = flushSearchResults
        that.getSearchResultCanvases = getSearchResultCanvases

        that.getItem = data.getItem
        that.contains = data.contains

        that.importFromURL = (url, cb) ->
          importFromURL url, ->
            cb() if cb?
