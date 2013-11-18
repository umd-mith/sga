# # Application

SGAReader.namespace "Application", (Application) ->
  #
  # ## Application.SharedCanvas
  #
  Application.namespace "SharedCanvas", (SharedCanvas) ->
    SharedCanvas.initInstance = (args...) ->
      MITHgrid.Application.initInstance "SGA.Reader.Application.SharedCanvas", args..., (that) ->
        options = that.options

        #
        # ### Manifest Import
        #

        #
        # manifestData holds Backbone collections populated with 
        # data from the shared canvas manifest.
        #
        manifestData = SGA.Reader.Data.Manifest.initInstance()

        if options.url?
          #
          # If we're given a URL in our options, then go ahead and load
          # it. For now, this is the only way to get data from a manifest.
          #
          manifestData.importFromURL options.url, ->
            0

        #
        # ### Presentation Coordination
        #

        presentations = []

        # This is a convenience method for creating a Shared Canvas
        # presentation and tying it to the data management application.
        # All presentations linked to this application will be coordinated
        # when the current sequence or canvas changes.
        #
        that.addPresentation = (config) ->
          0

    #
    SharedCanvas.builder = (config) ->
      that =
        manifests: {}

      manifestCallbacks = {}
      
      #
      # #### #onManifest
      #
      # * url: manifest URL
      # * cb: callback to call when the manifest is loaded and ready
      #
      # This function accepts a callback function that will be called
      # when the manifest has been loaded and processed. The callback will
      # receive one argument representing the Application.SharedCanvas
      # instance associated with the manifest URL.
      #
      that.onManifest = (url, cb=->) ->
        if that.manifests[url]?
          that.manifests[url].ready ->
            cb that.manifests[url]
        else
          manifestCallbacks[url] ?= []
          manifestCallbacks[url].push cb

      #
      # #### #addPresentation
      #
      # * el: the DOM element to contain the shared canvas presentation
      #
      # The element should have the following data- attributes:
      #
      # * data-manifest: the URL of the manifest
      # * data-types: a comma-separated list of annotation types to render
      #
      # The data types can be any of the following:
      #
      # * Image: render any image annotations
      # * Text: render any text annotations
      #
      # N.B.: non-text and non-image annotations will still render. For example,
      # zones will render regardless of the types. Zones inherit the types,
      # so zones in a Text-only rendering will only render text annotations.
      #
      that.addPresentation = (el) ->
        manifestUrl = $(el).data('manifest')
        if manifestUrl?
          manifest = that.manifests[manifestUrl]
          if !manifest?
            manifest = Application.SharedCanvas.initInstance
              url: manifestUrl
            that.manifests[manifestUrl] = manifest
            manifest.ready -> 
              cbs = manifestCallbacks[manifestUrl] || []
              cb(manifest) for cb in cbs
              delete manifestCallbacks[manifestUrl]

          manifest.run()
          types = $(el).data('types')?.split(/\s*,\s*/)
          that.onManifest manifestUrl, (manifest) ->  
            manifest.addPresentation
              types: types
              container: $(el)
        
      #
      # Now we go through and find all of the DOM elements that should be
      # made into shared canvas presentations.
      #
      if !config? 
        config = {}
      config.class ?= ".canvas"
      $(config.class).each (idx, el) -> that.addPresentation el
      that