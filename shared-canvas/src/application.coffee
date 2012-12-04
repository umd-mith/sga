# # Application
SGAReader.namespace "Application", (Application) ->
  Application.namespace "SharedCanvas", (SharedCanvas) ->
    SharedCanvas.initInstance = (args...) ->
      MITHGrid.Application.initInstance "SGA.Reader.Application.SharedCanvas", args..., (that) ->
        options = that.options

        presentations = []
        manifestData = SGA.Reader.Data.Manifest.initInstance()
        that.events.onItemsProcessedChange = manifestData.events.onItemsProcessedChange
        that.events.onItemsToProcessChange = manifestData.events.onItemsToProcessChange
        that.getItemsProcessed = manifestData.getItemsProcessed
        that.getItemsToProcess = manifestData.getItemsToProcess
        that.setItemsProcessed = manifestData.setItemsProcessed
        that.setItemsToProcess = manifestData.setItemsToProcess
        that.addItemsProcessed = manifestData.addItemsProcessed
        that.addItemsToProcess = manifestData.addItemsToProcess

        textSource = SGA.Reader.Data.TextStore.initInstance()

        that.withSource = (file, cb) ->
          textSource.withFile file, cb

        that.addPresentation = (config) ->
          # a presentation should only get a list of canvases
          # we really want a paging view that we can load with a 
          # sequence
          # we need a sequence selector
          # and a data view that provides a way to walk that sequence
          p = SGA.Reader.Presentation.Canvas.initInstance config.container,
            types: config.types
            application: -> that
            dataView: that.dataView.canvasAnnotations
          presentations.push [ p, config.container ]

        currentSequence = null

        that.events.onSequenceChange.addListener (s) ->
          currentSequence = s
          seq = that.dataStore.data.getItem currentSequence
          p = 0
          if seq?.sequence?
            p = seq.sequence.indexOf that.getCanvas()
          p = 0 if p < 0
          that.setPosition p
            
        that.events.onPositionChange.addListener (p) ->
          seq = that.dataStore.data.getItem currentSequence
          canvasKey = seq.sequence?[p]
          that.setCanvas canvasKey

        that.events.onCanvasChange.addListener (k) ->
          that.dataView.canvasAnnotations.setKey k
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
            syncer = MITHGrid.initSynchronizer ->
              that.addItemsToProcess 1
              that.dataStore.data.loadItems items, ->
                that.addItemsProcessed 1

            canvases = manifestData.getCanvases()
            that.addItemsToProcess canvases.length
            syncer.process canvases, (id) ->
              that.addItemsProcessed 1
              mitem = manifestData.getItem id
              item = 
                id: id
                type: 'Canvas'
                width: parseInt(mitem.exifwidth?[0], 10)
                height: parseInt(mitem.exifheight?[0], 10)
                label: mitem.dctitle || mitem.rdfslabel
              items.push item

            zones = manifestData.getZones()
            that.addItemsToProcess zones.length
            syncer.process zones, (id) ->
              that.addItemsProcessed 1
              zitem = manifestData.getItem id
              item =
                id: id
                type: 'Zone'
                width: parseInt(mitem.exifwidth?[0], 10)
                height: parseInt(mitem.exifheight?[0], 10)
                angle: parseInt(mitem.scnaturalAngle?[0], 10) || 0
                label: zitem.rdfslabel

              items.push item

            seq = manifestData.getSequences()
            that.addItemsToProcess seq.length
            syncer.process seq, (id) ->
              that.addItemsProcessed 1
              sitem = manifestData.getItem id
              item =
                id: id
                type: 'Sequence'
                label: sitem.rdfslabel

              # walk list of canvases
              seq = []
              seq.push sitem.rdffirst[0]
              sitem = manifestData.getItem sitem.rdfrest[0]
              while sitem.id? # manifestData.contains(sitem.rdfrest?[0])
                seq.push sitem.rdffirst[0]
                sitem = manifestData.getItem sitem.rdfrest[0]
              item.sequence = seq
              items.push item

            extractSpatialConstraint = (item, id) ->
              return unless id?
              constraint = manifestData.getItem id
              if 'oaFragmentSelector' in constraint.type
                if constraint.rdfvalue[0].substr(0,5) == "xywh="
                  item.shape = "Rectangle"
                  bits = constraint.rdfvalue[0].substr(6).split(",")
                  item.x = bits[0]
                  item.y = bits[1]
                  item.width = bits[2]
                  item.height = bits[3]
              # handle SVG constraints (rectangles, ellipses)
              # handle time constraints? for video/sound annotations?

            # now get the annotations we know something about handling
            annos = manifestData.getAnnotations()
            that.addItemsToProcess annos.length
            syncer.process annos, (id) ->
              that.addItemsProcessed 1
              aitem = manifestData.getItem id

              item =
                id: aitem.id

              if aitem.oahasStyle?
                styleItem = manifestData.getItem aitem.oahasStyle[0]
                if "text/css" in styleItem.dcformat
                  item.css = styleItem.cntchars

              # for now, we *assume* that the content annotation is coming
              # from a TEI file and is marked by begin/end pointers
              if "scContentAnnotation" in aitem.type
                target = manifestData.getItem aitem.oahasTarget?[0]
                if "oaSpecificTarget" in target.type
                  item.target = target.oahasSource
                  extractSpatialConstraint(item, target.oahasSelector?[0])
                else
                  item.target = aitem.oahasTarget

                textItem = manifestData.getItem aitem.oahasBody
                textItem = textItem[0] if $.isArray(textItem)
                textSpan = manifestData.getItem textItem.oahasSelector
                textSpan = textSpan[0] if $.isArray(textSpan)
                textSource.addFile(textItem.oahasSource);

                item.target = aitem.oahasTarget
                item.type = "TextContent"
                item.source = textItem.oahasSource
                item.start = parseInt(textSpan.oaxbegin?[0], 10)
                item.end = parseInt(textSpan.oaxend?[0], 10)

              else if "sgaLineAnnotation" in aitem.type
                # no body for now
                textItem = manifestData.getItem aitem.oahasTarget
                textItem = textItem[0] if $.isArray(textItem)
                textSpan = manifestData.getItem textItem.oahasSelector
                textSpan = textSpan[0] if $.isArray(textSpan)

                item.target = textItem.oahasSource
                item.start = parseInt(textSpan.oaxbegin?[0], 10)
                item.end = parseInt(textSpan.oaxend?[0], 10)
                item.type = "LineAnnotation"

              else if "sgaDeletionAnnotation" in aitem.type
                # no body or style for now
                textItem = manifestData.getItem aitem.oahasTarget
                textItem = textItem[0] if $.isArray(textItem)
                textSpan = manifestData.getItem textItem.oahasSelector
                textSpan = textSpan[0] if $.isArray(textSpan)

                item.target = textItem.oahasSource
                item.start = parseInt(textSpan.oaxbegin?[0], 10)
                item.end = parseInt(textSpan.oaxend?[0], 10)
                item.type = "DeletionAnnotation"

              else if "sgaAdditionAnnotation" in aitem.type
                # no body or style for now
                textItem = manifestData.getItem aitem.oahasTarget
                textItem = textItem[0] if $.isArray(textItem)
                textSpan = manifestData.getItem textItem.oahasSelector
                textSpan = textSpan[0] if $.isArray(textSpan)

                item.target = textItem.oahasSource
                item.start = parseInt(textSpan.oaxbegin?[0], 10)
                item.end = parseInt(textSpan.oaxend?[0], 10)
                item.type = "AdditionAnnotation"

              else if "scImageAnnotation" in aitem.type
                imgitem = manifestData.getItem aitem.oahasBody
                imgitem = imgitem[0] if $.isArray(imgitem)

                item.target = aitem.oahasTarget
                item.label = aitem.rdfslabel
                item.image = imgitem.oahasSource || aitem.oahasBody
                item.type = "Image"

              else if "scZoneAnnotation" in aitem.type
                target = manifestData.getItem aitem.oahasTarget
                extractSpatialConstraint item, target.hasSelector?[0]

                item.target = target.hasSource
                item.label = aitem.rdfslabel
                item.type = "ZoneAnnotation"

              if item.type?
                items.push item

            syncer.done()

    # we look for <div class="canvas" data-types="..." data-manifest="..."></div>
    # in the page and instantiate the application
    # each application handles a single manifest, but multiple canvases
    SharedCanvas.builder = (config) ->
      that =
        manifests: {}

      manifestCallbacks = {}

      updateProgressTracker = ->
      updateProgressTrackerVisibility = ->

      if config.progressTracker?
        updateProgressTracker = ->
          # go through and calculate all of the unfinished items
          n = 0
          d = 0
          for m, obj of that.manifests
            #if obj.getItemsToProcess() > obj.getItemsProcessed()
            n += obj.getItemsProcessed()
            d += obj.getItemsToProcess()
          config.progressTracker.setNumerator(n)
          config.progressTracker.setDenominator(d or 1)

        uptv = null
        uptvTimer = 1000

        updateProgressTrackerVisibility = ->
          if uptv?
            uptvTimer = 500
          else
            uptv = ->
              for m, obj of that.manifests
                if obj.getItemsToProcess() > obj.getItemsProcessed()
                  config.progressTracker.show()
                  uptvTimer /= 2
                  uptvTimer = 500 if uptvTimer < 500
                  setTimeout uptv, uptvTimer
                  return
              config.progressTracker.hide() if uptvTimer > 500
              uptvTimer *= 2
              uptvTimer = 10000 if uptvTimer > 10000
              setTimeout uptv, uptvTimer
            uptv()

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
            manifest = Application.SharedCanvas.initInstance
              url: manifestUrl
            that.manifests[manifestUrl] = manifest
            manifest.ready -> 
              cbs = manifestCallbacks[manifestUrl] || []
              cb(manifest) for cb in cbs
              delete manifestCallbacks[manifestUrl]
            manifest.events.onItemsToProcessChange.addListener updateProgressTracker
            manifest.events.onItemsProcessedChange.addListener updateProgressTracker
            updateProgressTrackerVisibility()
              
          manifest.run()
          types = $(el).data('types')?.split(/\s*,\s*/)
          that.onManifest manifestUrl, (manifest) ->
            manifest.addPresentation
              types: types
              container: $(el)
        
      config.class ?= ".canvas"
      $(config.class).each (idx, el) -> that.addPresentation el
      that
