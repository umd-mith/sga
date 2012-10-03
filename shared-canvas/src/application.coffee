# # Application
SGAReader.namespace "Application", (Application) ->
  Application.namespace "SharedCanvas", (SharedCanvas) ->
    SharedCanvas.initInstance = (args...) ->
      MITHGrid.Application.initInstance "SGA.Reader.Application.SharedCanvas", args..., (that) ->
        options = that.options

        presentations = []
        manifestData = SGA.Reader.Data.Manifest.initInstance()

        that.addPresentation = (config) ->
          # a presentation should only get a list of canvases
          # we really want a paging view that we can load with a 
          # sequence
          # we need a sequence selector
          # and a data view that provides a way to walk that sequence
          p = SGA.Reader.Presentation.Canvas.initInstance config.container,
            types: config.types
            dataView: that.dataView.canvasAnnotations
          presentations.push [ p, config.container ]

        currentSequence = null

        that.events.onSequenceChange.addListener (s) ->
          currentSequence = s
          seq = that.dataStore.data.getItem currentSequence
          p = seq.sequence.indexOf that.getCanvas()
          p = 0 if p < 0
          that.setPosition p
            
        that.events.onPositionChange.addListener (p) ->
          seq = that.dataStore.data.getItem currentSequence
          canvasKey = seq.sequence?[p]
          that.setCanvas canvasKey

        that.events.onCanvasChange.addListener (k) ->
          that.dataView.canvasAnnotations.setKey k
          console.log "things targeting the canvas:", that.dataView.canvasAnnotations.items()
          seq = that.dataStore.data.getItem currentSequence
          p = seq.sequence.indexOf k
          if p >= 0 && p != that.getPosition()
            that.setPosition p
          pp[0].setCanvas k for pp in presentations

        if options.url?
          # load url
          manifestData.importFromURL options.url, ->
            # now pull data out into data store
            # if multiple sequences, we want to add a control to allow
            # selection
            items = []
            canvases = manifestData.getCanvases()
            for id in canvases
              mitem = manifestData.getItem id
              item = 
                id: id
                type: 'Canvas'
                width: parseInt(mitem.exifwidth?[0], 10)
                height: parseInt(mitem.exifheight?[0], 10)
                label: mitem.dctitle || mitem.rdfslabel
              items.push item
            for id in manifestData.getSequences()
              sitem = manifestData.getItem id
              item =
                id: id
                type: 'Sequence'
                label: sitem.rdfslabel

              # walk list of canvases
              seq = []
              while manifestData.contains(sitem.rdffirst?[0])
                seq.push sitem.rdffirst[0]
                sitem = manifestData.getItem sitem.rdfrest[0]
              item.sequence = seq
              items.push item
            for id in manifestData.getAnnotations()
              aitem = manifestData.getItem id
              if "scImageAnnotation" in aitem.type
                imgitem = manifestData.getItem aitem.oahasBody
                imgitem = imgitem[0] if $.isArray(imgitem)
                items.push
                  id: aitem.id
                  target: aitem.oahasTarget
                  label: aitem.rdfslabel
                  image: imgitem.oahasSource || aitem.oahasBody
                  type: "Image"

            console.log items
            that.dataStore.data.loadItems items

    # we look for <div class="canvas" data-types="..." data-manifest="..."></div>
    # in the page and instantiate the application
    # each application handles a single manifest, but multiple canvases
    SharedCanvas.builder = (config) ->
      that = {
        manifests: {}
      }

      manifestCallbacks = {}

      that.onManifest = (url, cb) ->
        if that.manifests[url]?
          that.manifests[url].ready ->
            cb that.manifests[url]
        else
          manifestCallbacks[url] ?= []
          manifestCallbacks[url].push cb

      that.addPresentation = (el) ->
        manifestUrl = $(el).data('manifest')
        if manifestUrl?
          manifest = that.manifests[manifestUrl]
          if !manifest?
            console.log "Creating manifest"
            manifest = Application.SharedCanvas.initInstance
              url: manifestUrl
            that.manifests[manifestUrl] = manifest
            manifest.ready -> 
              cbs = manifestCallbacks[manifestUrl] || []
              cb(manifest) for cb in cbs
              delete manifestCallbacks[manifestUrl]
              console.log "manifest ready for ", manifestUrl
          console.log("Running manifest app");
          manifest.run()
          types = $(el).data('types')?.split(/\s*,\s*/)
          that.onManifest manifestUrl, (manifest) ->
            console.log "adding presentation"
            manifest.addPresentation
              types: types
              container: $(el)
        
      config.class ?= ".canvas"
      $(config.class).each (idx, el) -> that.addPresentation el
      that
