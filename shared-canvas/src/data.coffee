# # Data Managment
SGAReader.namespace "Data", (Data) ->

  #
  # ## Data.TextStore
  #
  Data.namespace "TextStore", (TextStore) ->
    TextStore.initInstance = (args...) ->
      MITHGrid.initInstance args..., (that) ->
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

    Manifest.initInstance = (args...) ->
      MITHGrid.initInstance "SGA.Reader.Data.Manifest", args..., (that) ->
        options = that.options

        data = MITHGrid.Data.Store.initInstance()

        that.size = -> data.size()

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
            success: (data) -> that.importJSON data, cb
            error: cb

        # we want to get the rdf/JSON version of things if we can
        that.importJSON = (json, cb) ->
          # we care about certain namespaces - others we ignore
          # those we care about, we translate for datastore
          # {nsPrefix}{localName}
          items = []
          syncer = MITHGrid.initSynchronizer()
          subjects = (s for s of json) # when json.hasOwnProperty(s))
          that.addItemsToProcess subjects.length
          syncer.process subjects, (s) ->
            predicates = json[s]
            item =
              id: s
            for p, os of predicates
               values = []
               if p == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
                 for o in os
                   if o.type == "uri"
                     for ns, prefix of NS
                       if o.value[0...ns.length] == ns
                         values.push prefix + o.value.substr(ns.length)
                 item.type = values
               else
                 for o in os
                   if o.type == "literal"
                     values.push o.value
                   #
                   # Sometimes, references to blank nodes are wrapped in
                   # parenthesis, but the subject IDs will be with a leading
                   # _:. For example, an object uri/bnode in the form
                   # "(123abc)" refers to a resource with the URI
                   # "_:123abc".
                   #
                   else if o.type == "uri"
                     if o.value.substr(0,1) == "(" and o.value.substr(-1) == ")"
                       values.push "_:" + o.value.substr(1,o.value.length-2)
                     else
                       values.push o.value
                   else if o.type == "bnode"
                     if o.value.substr(0,1) == "(" and o.value.substr(-1) == ")"
                       values.push "_:" + o.value.substr(1,o.value.length-2)
                     else
                       values.push o.value
                     
                 if values.length > 0
                   for ns, prefix of NS
                     if p.substr(0, ns.length) == ns
                       pname = prefix + p.substr(ns.length)
                       item[pname] = values
            if !item.type? or item.type.length == 0
              item.type = 'Blank'
 
            #
            # If the manifest indicates that another document describes
            # this resource, then we throw away the current item we've built
            # and load the data before continuing processing for this
            # resource.
            #
            # We are not using this in the current SGA manifest, so this
            # might be broken - but this is where support would be hooked in.
            #
            if item.oreisDescribedBy?.length > 0
              for url in item.oreisDescribedBy
                syncer.increment()
                importFromURL url, syncer.decrement
            else
              items.push item 
            that.addItemsProcessed 1

          syncer.done ->
            that.addItemsProcessed 1
            setTimeout ->
              for item in items
                if data.contains(item.id)
                  data.updateItems [ item ]
                else
                  data.loadItems [ item ]
              cb() if cb?
            , 0

        itemsWithType = (type) ->
          type = [ type ] if !$.isArray(type)
          types = MITHGrid.Data.Set.initInstance type
          data.getSubjectsUnion(types, "type").items()

        #
        # Get things of different types. For example, "scCanvas" gets
        # all of the canvas items.
        #
        that.getCanvases    = -> itemsWithType 'scCanvas'
        that.getZones       = -> itemsWithType 'scZone'
        that.getSequences   = -> itemsWithType 'scSequence'
        that.getAnnotations = -> itemsWithType 'oaAnnotation'

        that.getItem = data.getItem
        that.contains = data.contains

        that.importFromURL = (url, cb) ->
          importFromURL url, ->
            cb() if cb?
