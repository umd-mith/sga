###
# SGA Shared Canvas v0.0.1
#
# **SGA Shared Canvas** is a shared canvas reader written in CoffeeScript.
#
#  
# Date: Wed Oct 24 15:32:00 2012 -0400
#
# License TBD.
#
###

(($, MITHGrid) ->
  # The application uses the SGA.Reader namespace.
  MITHGrid.globalNamespace "SGA"
  SGA.namespace "Reader", (SGAReader) ->
    # # Core Utilities
    # # Data Managment
    SGAReader.namespace "Data", (Data) ->
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
                  next if fileContents[file]? or loadingFiles[file]?
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
    
      Data.namespace "Manifest", (Manifest) ->
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
    
        Manifest.initInstance = (args...) ->
          MITHGrid.initInstance "SGA.Reader.Data.Manifest", args..., (that) ->
            options = that.options
    
            data = MITHGrid.Data.Store.initInstance()
    
            loadedUrls = []
    
            importFromURL = (url, cb) ->
              if url in loadedUrls
                cb()
                return
              loadedUrls.push url
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
              # {nsPrefix}-{localName}
              syncer = MITHGrid.initSynchronizer cb
              items = []
              for s, ps of json
                item =
                  id: s
                for p, os of ps
                   values = []
                   if p == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
                     for o in os
                       if o.type == "uri"
                         for ns, prefix of NS
                           if prefix in [ "sc", "sga", "oa", "oax" ]
                             if o.value[0...ns.length] == ns
                               values.push prefix + o.value.substr(ns.length)
                     item.type = values
                   else
                     for o in os
                       if o.type == "literal"
                         values.push o.value
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
    
                if item.oreisDescribedBy?.length > 0
                  for url in item.oreisDescribedBy
                    syncer.increment()
                    importFromURL url, syncer.decrement
                else
                  items.push item 
    
              for item in items
                if data.contains(item.id)
                  data.updateItems [ item ]
                else
                  data.loadItems [ item ]
              syncer.done()
    
            itemsWithType = (type) ->
              type = [ type ] if !$.isArray(type)
              types = MITHGrid.Data.Set.initInstance type
              data.getSubjectsUnion(types, "type").items()
    
            #
            # Get things of different types
            #
            # "sc-Canvas" <- type
            #
            that.getCanvases = -> itemsWithType 'scCanvas'
            that.getSequences = -> itemsWithType 'scSequence'
            that.getAnnotations = -> itemsWithType 'oaAnnotation'
    
            that.getItem = data.getItem
            that.contains = data.contains
    
            that.importFromURL = (url, cb) ->
              importFromURL url, ->
                cb() if cb?

    # # Presentations
    SGAReader.namespace "Presentation", (Presentation) ->
      Presentation.namespace "Canvas", (Canvas) ->
        Canvas.initInstance = (args...) ->
          MITHGrid.Presentation.initInstance "SGA.Reader.Presentation.Canvas", args..., (that, container) ->
            # We want to draw everything that annotates a Canvas
            # this would be anything with a target = the canvas
            options = that.options
    
            # we need a nice way to get the span of text from the tei
            # and then we apply any annotations that modify how we display
            # the text before we create the svg elements - that way, we get
            # things like line breaks
            #
            # .target = tei.id AND
            # ( .start <= item.end[0] OR
            #   .end >= item.start[0] )
            #
    
            highlightDS = null
    
            annoExpr = that.dataView.prepare(['!target'])
    
            #if 'Text' in (options.types || [])
            #  highlightDS = MITHGrid.Data.RangePager.initInstance
            #    dataStore: MITHGrid.Data.View.initInstance
            #      dataStore: that.dataView
            #      type: ['LineAnnotation', 'DeleteAnnotation', 'AddAnnotation']
            #    leftExpressions: [ '.end' ]
            #    rightExpressions: [ '.start' ]
    
              # we also need to know when we have one of these annotations
              # getting updated - we might be able to hook into the
              # highlightDS object for this and leave the following
              # rendering.update method for tracking changes to the
              # underlying unstructured text range
    
              #highlightDS.events.onModelChange.addListener (m, ids) ->
              #  console.log ids
                
            pendingSVGfctns = []
            SVG = (cb) ->
              pendingSVGfctns.push cb
    
            svgRootEl = $("""
              <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
                   xmlns:xlink="http://www.w3.org/1999/xlink"
                   width="0" height="0"
               >
              </svg>
            """)
            container.append(svgRootEl)
            svgRoot = $(svgRootEl).svg 
              onLoad: (svg) ->
                SVG = (cb) -> cb(svg)
                cb(svg) for cb in pendingSVGfctns
                pendingSVGfctns = null
            canvasWidth = null
            canvasHeight = null
            SVGHeight = null
            SVGWidth = $(container).width()*19/20
            MITHGrid.events.onWindowResize.addListener ->
              SVGWidth = $(container).width() * 19/20
              if canvasWidth?
                that.setScale (SVGWidth / canvasWidth)
              
    
            that.events.onScaleChange.addListener (s) ->
              if canvasWidth? and canvasHeight?
                SVGHeight = canvasHeight * s
                SVG (svgRoot) ->
                  svgRootEl.attr
                    width: SVGWidth
                    height: SVGHeight
                    viewbox: "0 0 #{SVGWidth} #{SVGHeight}"
                  svgRootEl.css
                    width: SVGWidth
                    height: SVGHeight
                    border: "0.5em solid #eeeeee"
                    "border-radius": "5px"
                    "background-color": "#ffffff"
    
            # the data view is managed outside the presentation
            dataView = MITHGrid.Data.SubSet.initInstance
              dataStore: options.dataView
              expressions: [ '!target' ]
              key: null
    
            that.events.onCanvasChange.addListener (canvas) ->
              dataView.setKey(canvas)
              item = dataView.getItem canvas
              # now make SVG canvas the size of the canvas (for now)
              # eventually, we'll constrain the size but maintain the
              # aspect ratio
              canvasWidth = item.width?[0] || 1
              canvasHeight = item.height?[0] || 1
              that.setScale (SVGWidth / canvasWidth)
    
            that.addLens 'Image', (container, view, model, id) ->
              return unless 'Image' in (options.types || [])
              rendering = {}
    
              item = model.getItem id
              # for now, we assume a full mapping - image to full canvas/container
              svgImage = null
              SVG (svgRoot) ->
                svgImage = svgRoot.image(0, 0, "100%", "100%", item.image?[0], {
                  preserveAspectRatio: 'none'
                })
              rendering.update = (item) ->
                # do nothing for now
              rendering.remove = ->
                SVG (svgRoot) ->
                  svgRoot.remove svgImage
              rendering
    
            that.addLens 'TextContent', (container, view, model, id) ->
              return unless 'Text' in (options.types || [])
              rendering = {}
              app = options.application()
              item = model.getItem id
              # for now, we assume that all of the text gets splatted onto
              # the SVG canvas - we may want to play with doing it one
              # glyph at a time, but that's probably going to be too expensive
              svgText = null
    
              processNode = (info) ->
                classes = []
                if 'LineAnnotation' in info.modes
                  classes.push 'line'
                if 'AdditionAnnotation' in info.modes
                  classes.push 'addition'
                if 'DeletionAnnotation' in info.modes
                  classes.push 'deletion'
    
                classes.push "text" if classes.length == 0
    
                return {
                  type: 'span'
                  text: info.acc
                  classes: classes.join(' ')
                  modes: info.modes
                }
    
              # takes a text string and a series of mods made at positions in the string
              # returns a sequence of DOM elements and a grouping of elements based on
              # type of mod being made
              compileText = (info) ->
                text = info.text
                mods = info.mods
                offset = info.offset 
      
                current_el = 
                  acc: ''
                  modes: [ ]
      
                results = []
                br_pushed = false
      
                for pos in [ 0 ... text.length ]
                  if !mods[pos+offset]?
                    br_pushed = false unless text[pos].match(/^\s+$/)
                    current_el.acc += text[pos]
                  else 
                    if current_el.acc.match(/^\s*$/)
                      current_el.acc = ''
                    else
                      results.push processNode(current_el)
      
                    current_el.acc = text[pos]
                    for mod in mods[pos+offset]
                      if mod.type == "LineAnnotation"
                        if !br_pushed
                          results.push { type: 'br', modes: [], acc: '' }
                          br_pushed = true
                      if mod.action == 'start'
                        current_el.modes.push mod.type
                      if mod.action == 'end'
                        current_el.modes = (i for i in current_el.modes when i != mod.type)
    
                results.push processNode(current_el)
                results
    
              text = ""
              mods = {}
              textContainer = null
    
              setMod = (pos, pref, type) ->
                pos = pos[0] if $.isArray(pos)
                mods[pos] = [] unless mods[pos]?
                type = type[0] if $.isArray(type)
                mods[pos].push 
                  action: pref
                  type: type
    
              SVG (svgRoot) ->
                textContainer = document.createElementNS('http://www.w3.org/2000/svg', 'foreignObject' )
                $(textContainer).attr("x", 0).attr("y", 0).attr("width", "100%").attr("height", "100%")
                svg = svgRoot.root()
                svg.appendChild(textContainer)
    
    
                app.withSource item.source[0], (content) ->
                  text = content.substr(item.start[0], item.end[0])
                  #highlightDS.setKeyRange item.start[0], item.end[0]
                  # now we mark up the text as indicated by the highlights
                  # we want annotations that satisfy the following:
                  #
                  # might be useful to have a data store that lets us easily and
                  # quickly find overlapping ranges
                  #
                  # TODO: still need to manage the .target = tei.id bit
                  #
                  #highlightDS.visit (id) ->
                  #  # now apply annotation to text
                  #  hitem = highlightDS.getItem id
                  #  setMod hitem.start, 'start', hitem.type
                  #  setMod hitem.start, 'end', hitem.type
    
                  for annoId in annoExpr.evaluate(item.source)
                    hitem = model.getItem annoId
                    start = hitem.start[0]
                    end = hitem.end[0]
                    if start <= item.end[0] && end >= item.start[0]
                      start = item.start[0] if start < item.start[0]
                      end = item.end[0] if end > item.end[0]
                      setMod hitem.start, 'start', hitem.type
                      setMod hitem.end, 'end', hitem.type
    
                  nodes = compileText
                    text: text
                    mods: mods
                    offset: item.start[0]
    
                  tags = {}
                  bodyEl = document.createElementNS('http://www.w3.org/1999/xhtml', 'body')
                  rootEl = document.createElement('div')
                  $(rootEl).addClass("text-content")
                  bodyEl.appendChild(rootEl)
                  
                  for node in nodes
                    el = $("<#{node.type} />")
                    if node.type == "br"
                      $(rootEl).append($("<span class='linebreak'></span>"))
                    else
                      el.text(node.text)
                    el.addClass(node.classes)
                    $(rootEl).append(el)
                    for mode in node.modes
                      tags[mode] ?= []
                      tags[mode].push el
                  textContainer.appendChild(bodyEl)
    
                  #svgText = svgRoot.textpath(texts, "#textpath-#{id}", texts.string(text))
                  #svgRoot.text(svgText)
                  #svgText = svgRoot.text(0, 100, text, { "font-size": "12pt" })
    
              rendering.update = (item) ->
                # do nothing for now
              rendering.remove = ->
                  SVG (svgRoot) ->
                    svgRoot.remove textContainer
              rendering

    # # Controllers
    # # Component
    SGAReader.namespace "Component", (Component) ->
      Component.namespace "SequenceSelector", (SequenceSelector) ->
        SequenceSelector.initInstance = (args...) ->
          MITHGrid.Presentation.initInstance "SGA.Reader.Component.SequenceSelector", args..., (that, container) ->
            options = that.options
            # container should be a <select/> element
            that.addLens 'Sequence', (container, view, model, id) ->
              rendering = {}
              item = model.getItem id
              el = $("<option></option>")
              el.attr
                value: id
              el.text item.label?[0]
              $(container).append(el)
    
            $(container).change ->
              that.setSequence $(container).val()
    
            that.finishDisplayUpdate = ->
              that.setSequence $(container).val()

    # # Application
    SGAReader.namespace "Application", (Application) ->
      Application.namespace "SharedCanvas", (SharedCanvas) ->
        SharedCanvas.initInstance = (args...) ->
          MITHGrid.Application.initInstance "SGA.Reader.Application.SharedCanvas", args..., (that) ->
            options = that.options
    
            presentations = []
            manifestData = SGA.Reader.Data.Manifest.initInstance()
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
    
                # now get the annotations we know something about handling
                for id in manifestData.getAnnotations()
                  aitem = manifestData.getItem id
    
                  # for now, we *assume* that the content annotation is coming
                  # from a TEI file and is marked by begin/end pointers
                  if "scContentAnnotation" in aitem.type
                    textItem = manifestData.getItem aitem.oahasBody
                    textItem = textItem[0] if $.isArray(textItem)
                    textSpan = manifestData.getItem textItem.oahasSelector
                    textSpan = textSpan[0] if $.isArray(textSpan)
                    textSource.addFile(textItem.oahasSource);
                    items.push
                      id: aitem.id
                      target: aitem.oahasTarget
                      type: "TextContent"
                      source: textItem.oahasSource
                      start: parseInt(textSpan.oaxbegin[0], 10)
                      end: parseInt(textSpan.oaxend[0], 10)
    
                  if "sgaLineAnnotation" in aitem.type
                    # no body for now
                    textItem = manifestData.getItem aitem.oahasTarget
                    textItem = textItem[0] if $.isArray(textItem)
                    textSpan = manifestData.getItem textItem.oahasSelector
                    textSpan = textSpan[0] if $.isArray(textSpan)
                    items.push
                      id: aitem.id
                      target: textItem.oahasSource
                      start: parseInt(textSpan.oaxbegin[0], 10)
                      end: parseInt(textSpan.oaxend[0], 10)
                      type: "LineAnnotation"
    
                  if "sgaDeletionAnnotation" in aitem.type
                    # no body or style for now
                    textItem = manifestData.getItem aitem.oahasTarget
                    textItem = textItem[0] if $.isArray(textItem)
                    textSpan = manifestData.getItem textItem.oahasSelector
                    textSpan = textSpan[0] if $.isArray(textSpan)
                    items.push
                      id: aitem.id
                      target: textItem.oahasSource
                      start: parseInt(textSpan.oaxbegin[0], 10)
                      end: parseInt(textSpan.oaxend[0], 10)
                      type: "DeletionAnnotation"
    
                  if "sgaAdditionAnnotation" in aitem.type
                    # no body or style for now
                    textItem = manifestData.getItem aitem.oahasTarget
                    textItem = textItem[0] if $.isArray(textItem)
                    textSpan = manifestData.getItem textItem.oahasSelector
                    textSpan = textSpan[0] if $.isArray(textSpan)
                    items.push
                      id: aitem.id
                      target: textItem.oahasSource
                      start: parseInt(textSpan.oaxbegin[0], 10)
                      end: parseInt(textSpan.oaxend[0], 10)
                      type: "AdditionAnnotation"
    
                  if "scImageAnnotation" in aitem.type
                    imgitem = manifestData.getItem aitem.oahasBody
                    imgitem = imgitem[0] if $.isArray(imgitem)
                    items.push
                      id: aitem.id
                      target: aitem.oahasTarget
                      label: aitem.rdfslabel
                      image: imgitem.oahasSource || aitem.oahasBody
                      type: "Image"
    
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
            
          config.class ?= ".canvas"
          $(config.class).each (idx, el) -> that.addPresentation el
          that


)(jQuery, MITHGrid)

MITHGrid.defaults 'SGA.Reader.Application.SharedCanvas',
  dataStores:
    data:
      types:
        Sequence: {}
        Canvas: {}
      properties:
        target:
          valueType: 'item'
  dataViews:
    canvasAnnotations:
      dataStore: 'data'
      type: MITHGrid.Data.SubSet
      expressions: [ '!target' ]
    sequences:
      dataStore: 'data'
      types: [ 'Sequence' ]
  variables:
    Canvas:
      is: 'rw'
    Sequence:
      is: 'rw'
    Position:
      is: 'rw'

MITHGrid.defaults 'SGA.Reader.Component.SequenceSelector',
  variables:
    Sequence:
      is: 'rw'

MITHGrid.defaults 'SGA.Reader.Presentation.Canvas',
  variables:
    Canvas:
      is: 'rw'
    Scale:
      is: 'rw'
