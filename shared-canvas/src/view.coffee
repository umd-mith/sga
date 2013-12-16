# # Model Views
# This file handles views of models and collections.

SGASharedCanvas.View = SGASharedCanvas.View or {}

( ->

  # MAIN APPLICATION VIEW
	class SGASharedCanvas.Application extends Backbone.View

    # This is the top-level piece of UI, 
    # so we bind it to an element already present in the HTML.
    el: '#main-content'

    initialize: (config={}) ->     

      manifestUrl = $("#SGASharedCanvasViewer").data('manifest')
      # manifest = SGASharedCanvas.Data.importFullJSONLD manifestUrl 

      # Instantiate manifests collection and view
      manifests = SGASharedCanvas.Data.Manifests
      new ManifestsView collection : manifests
      # Add manifest from DOM. This triggers data collection and rendering.
      manifest = manifests.add
        url: manifestUrl
      manifest.fetch()      

      # Activate Routers
      Backbone.history.start()

  #
  # Our Views have properties that are not reflected in the data models. 
  # The models should be considered read-only from the views
  # 
  # In order to manage this properties, we mix Backbone's Events module
  # with the properties and define general setters and getters to fire Backbone events.
  #
  class ViewProperties

    constructor: (@variables) ->
      _.extend @, Backbone.Events

    set: (prop, val) ->
      if @variables[prop]?
        @variables[prop] = val
        @trigger 'change', @variables
        @trigger 'all', @variables
        @trigger 'change:'+prop, val, @variables
      else 
        throw new Error "View property #{prop} does not exist."

    get: (prop) ->
      if @variables[prop]? 
        @variables[prop]
      else 
        throw new Error "View property #{prop} does not exist."

  # Manifests view
  class ManifestsView extends Backbone.View

    initialize: ->
      @listenTo @collection, 'add', @addOne

    addOne: (model) ->
      new ManifestView model: model

    render: ->
      @

  # Manifest view
  class ManifestView extends Backbone.View

    # Instead of generating a new element, bind to the existing skeleton of
    # already present in the HTML.
    el: '#SGASharedCanvasViewer'

    # Delegated events for UI components
    events: 
      # Pager
      'click #sequence-nav #next-page': 'nextPage'
      'click #sequence-nav #prev-page': 'prevPage'
      'click #sequence-nav #first-page': 'firstPage'
      'click #sequence-nav #last-page': 'lastPage'
 
    nextPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqPage")+1
      Backbone.history.navigate("#/page/"+newPage)

    prevPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqPage")-1
      Backbone.history.navigate("#/page/"+newPage)

    initialize: ->

      # Set view properties
      @variables = new ViewProperties 
        seqPage: 0
        seqMin: 1
        seqMax: 0

      # Add views for child collections right away
      new CanvasesView collection: @model.canvases

      # Pager
      firstEl = $('#sequence-nav #first-page')
      prevEl = $('#sequence-nav #prev-page')
      nextEl = $('#sequence-nav #next-page')
      lastEl = $('#sequence-nav #last-page')

      @listenTo @variables, 'change:seqPage', (n) ->
        if n > @variables.get "seqMin"
          firstEl.removeClass "disabled"
          prevEl.removeClass "disabled"
        else
          firstEl.addClass "disabled"
          prevEl.addClass "disabled"

        if n < @variables.get "seqMax"
          nextEl.removeClass "disabled"
          lastEl.removeClass "disabled"
        else
          nextEl.addClass "disabled"
          lastEl.addClass "disabled"

      # When a new canvas is requested through a Router, fetch the right canvas data.
      @listenTo SGASharedCanvas.Data.Manifests, 'page', (n) ->

        # First of all, destroy any canvas already loaded. We do this for two reasons:
        # 1. it avoids piling up canvases data in the browser memory
        # 2. it causes previously instantiated views to destry themselves and make room for the new one.
        @model.canvases.reset()

        fetchCanvas = =>
          # For now we assume there is only one sequence.
          # Eventually this should be on a sequence view.
          # From the sequence, we locate the correct canvas id
          sequence = @model.sequences.first()

          canvases = sequence.get "canvases"

          @variables.set "seqMax", canvases.length
          @variables.set "seqPage", parseInt(n)

          n = canvases.length if n > canvases.length
          canvasId = canvases[n-1]
          # Create the view
          canvas = @model.canvases.add
            id : canvasId
          # Finally fetch the data. This will cause the views to render.
          canvas.fetch @model

        # Make sure manifest is loaded        
        if @model.sequences.length > 0
          fetchCanvas()
        else
          @model.once "sync", fetchCanvas    

    render: ->
      @

  # Canvases view
  class CanvasesView extends Backbone.View

    initialize: ->
      @listenTo @collection, 'add', @addOne

    addOne: (c) ->
      # Only trigger views once the model contains canvas data (but not subcollections yet)
      @listenToOnce c, 'sync', ->
        new CanvasView model: c

    render: ->
      @

  # Canvas view
  class CanvasView extends Backbone.View

    initialize: ->
      @listenTo @model, 'remove', @remove

      @render()         

    render: ->
      # Here we collect data-types expressed in HTML and
      # we organize further collections according to them.

      areas = []

      tpl = $($('#canvas-tpl').html())

      tpl.find('.sharedcanvas').each ->
        data = $(@).data()
        data["el"] = @
        areas.push data

      # Attach the template to #mainSharedCanvas (must be provided in the HTML)
      # Eventually we could take the destination div as a paramenter when initializing the app.
      @$el.append tpl
      $("#mainSharedCanvas").append @$el

      for area in areas        
        # We use canvas data to render views for the areas.
        # Each area is an independent view on the canvas data.
        new ViewerAreaView 
          model: @model
          el: area.el
          types: area.types.split(" ")     
      @

  # General area view, declaring variables that can be tracked with events
  class AreaView extends Backbone.View
    initialize: (options) ->
      # Set view properties
      @variables = new ViewProperties 
        height: 0
        width : 0
        x     : 0
        y     : 0
        scale : 0

      # Set values if provided
      if options.vars? and typeof options.vars == 'object'
        for k, v of options.vars
          @variables.set k, v


      # Example of listeners
      # @variables.on 
      #   'change:width' : -> console.log 'w'
      #   'change:height' : -> console.log 'h'   

  # ViewerArea View
  class ViewerAreaView extends AreaView

    initialize: (options) ->
      super
      # When rendering, we create sub-views for each type required
      @types = options.types      

      @render()

    render: (container) ->
      @$el.css 'overflow': 'hidden'

      container = $("<div></div>")
      @$el.append(container)
      $(container).height(Math.floor(@$el.width() * 4 / 3))
      $(container).css
        'background-color': 'white'
        'z-index': 0

      canvasWidth = null
      canvasHeight = null

      # Is this needed??
      baseFontSize = 150 # in terms of the SVG canvas size - about 15pt
      DivHeight = null
      DivWidth = Math.floor(@$el.width()*20/20)
      @$el.height(Math.floor(@$el.width() * 4 / 3))

      # This figures out the scale for our further calculations.
      resizer = =>
        DivWidth = Math.floor(@$el.width()*20/20,10)
        if canvasWidth? and canvasWidth > 0
          @variables.set 'scale', DivWidth / canvasWidth
        if canvasHeight? and canvasHeight > 0
          @$el.height(DivHeight = Math.floor(canvasHeight * @variables.get 'scale'))

      $(window).on "resize", resizer

      container.css
        'border': '1px solid grey'
        'background-color': 'white'

      @listenTo @variables, 'change:scale', (s) ->
        if canvasWidth? and canvasHeight?
          DivHeight = Math.floor(canvasHeight * s)
        container.css
          'font-size': (Math.floor(baseFontSize * s * 10) / 10) + "px"
          'line-height': (Math.floor(baseFontSize * s * 11.5) / 10) + "px"
          'height': DivHeight
          'width': DivWidth

      canvasWidth = if @model.get("width")? then @model.get("width") else 0
      canvasHeight = if @model.get("height")? then @model.get("height") else 0
      resizer()

      @variables.set 'height', canvasHeight
      @variables.set 'width', canvasWidth
      @variables.set 'x', @model.get("x") if @model.get("x")?
      @variables.set 'y', @model.get("y") if @model.get("y")?

      @renderSub container

      @

    renderSub: (container) ->
      # In each area, create sub-view for the content required 

      addText = =>
        container.append new ContentsView(
          collection: @model.contents
          el: container
          vars: @variables.variables # Pass on variables set in this view
        ).render().el
      addImages = =>
        # container.append new ImagesView(
        #   collection: @model.images
        #   el: container
        #   vars: @variables.variables # Pass on variables set in this view
        # ).render().el

      for type in @types
      # Accepted data-types "All", "Image", "Text". 
      # Eventually Audio, Video, NotatedMusic...
        switch type
          when "All"              
            addText()
            addImages()
          when "Image"
            addImages()
          when "Text"
            addText()

  
  #
  # TEXT VIEWS
  #

  class ContentsView extends Backbone.View

    initialize: (options) ->
      # Pass on properties set on the ViewerArea
      @variables = options.vars
      @listenTo @collection, 'add', @addOne

    addOne: (model) ->
      @$el.append new ContentView( 
        model: model 
        vars: @variables 
      ).render().el

    render: ->
      @


  class ContentView extends AreaView

    render: ->
      @$el.css
        overflow: 'auto'
        position: 'absolute'
        # border: '1px solid red' #debug

      rootEl = $("<div></div>")
      $(rootEl).addClass("text-content")
      $(rootEl).attr("id", @model.get("@id"))
      $(rootEl).css
        "white-space": "nowrap"

      @$el.append(rootEl)

      #
      # If we're not given an offset and size, then we assume that we're
      # covering the entire targeted zone or canvas.
      #
      x = if @model.get("x")? then @model.get("x") else 0
      y = if @model.get("y")? then @model.get("y") else 0
      width = if @model.get("width")? then @model.get("width") else @variables.get("width") - x
      height = if @model.get("height")? then @model.get("height") else @variables.get("height") - y

      $(@$el).css
        left: Math.floor(16 + x * @variables.get('scale')) + "px"
        top: Math.floor(y * @variables.get('scale')) + "px"
        width: Math.floor(width * @variables.get('scale')) + "px"
        height: Math.floor(height * @variables.get('scale')) + "px"

      #
      # Here we embed the text-based view.
      # Any text-based positioning will have to be handled by
      # the TextContent view.
      #      
      new TextAnnotationsView
        collection: @model.textItems
        el: rootEl
        vars : @variables.variables # Pass on properties set in this view

      @

  #TODOs HERE
  class TextAnnotationsView extends AreaView

    initialize: (options) ->
      super
      @listenTo @collection, 'add', @addOne

      @lastLine = -1
      @currentLine = 0
      @currentLineEl = $("<div></div>")
      @$el.append @currentLineEl

      @render()

    addOne: (model) ->
      # console.log model
      # Instiate different views depending on the type of annotation.
      type = model.get "type"
      switch
        when "Text" in type or "sgaLineAnnotation" in type or "sgaDeletionAnnotation" in type or "sgaSearchAnnotation" in type    
          textAnnoView = new TextAnnoView 
            model: model 
          @currentLineEl.append textAnnoView.render()?.el
        #TODO: when "sgaAdditionAnnotation"
        when "LineBreak" in type
          # new line container
          @currentLineEl = $("<div></div>")
          @$el.append @currentLineEl

    render: ->
      @variables.on 'change:width', (w) ->
        @$l.attr('width', w/10)

      # SCALE?

      #
      # We draw each text span type the same way. We rely on the
      # item.type to give us the CSS classes we need for the span
      #
      # lines = {}
      # lineAlignments = {}
      # lineIndents = {}
      # scaleSettings = []
      # currentLine = 0

      #
      # For now, we are dependent on the collection to retain the ordering
      # of items based on insertion order.
      #
      # that.addLens 'AdditionAnnotation', additionLens
      # that.addLens 'DeletionAnnotation', annoLens
      # that.addLens 'SearchAnnotation', annoLens
      # that.addLens 'LineAnnotation', annoLens
      # that.addLens 'Text', -> #annoLens

      #
      # Line breaks are different. We just want to add an explicit
      # break without any classes or styling.
      #
      # that.addLens 'LineBreak', (container, view, model, id) ->          
      #   item = model.getItem id
      #   if item.align?.length > 0
      #     lineAlignments[currentLine] = item.align[0]
      #   if item.indent?.length > 0
      #     lineIndents[currentLine] = Math.floor(item.indent[0]) or 0
      #   currentLine += 1
        # null
      @

  class TextAnnoView extends Backbone.View
    tagName: "span"

    render: ->     
      @$el.css 'display', 'inline-block'
      @$el.text @model.get "text"
      @$el.addClass @model.get("type").join(" ")

      icss = @model.get "css"
      if icss? and not /^\s*$/.test(icss) then @$el.attr "style", icss
      
      content = @model.get("text").replace(/\s+/g, " ")
      if content == " "
        charWidth = 0
      else
        charWidth = content.length

      if charWidth == 0
        return null

      # lines[currentLine] ?= []
      # lines[currentLine].push rendering
      # rendering.line = currentLine
      # rendering.positioned = false
      # rendering.setScale = (s) ->
      
      # rendering.afterLayout = ->
      #   rendering.width = rendering.$el.width() / that.getScale()
      
      # rendering.remove = ->
      #   el.remove()
      #   lines[rendering.line] = (r for r in lines[rendering.line] when r != rendering)

      # rendering.update = (item) ->
      #   el.text item.text[0]
      @

  #
  # IMAGE VIEWS
  #

  class ImagesView extends Backbone.View

    initialize: (options) ->
      # Pass on properties set on the ViewerArea
      @variables = options.vars
      @listenTo @collection, 'add', @addOne

    addOne: (model) ->
      # This viewer supports JP2 if a DJATOKA service is provided
      if model.get("format") == "image/jp2" and model.get("service")?
        # new ImageDjatokaView( 
        #   el: @$el
        #   model: model 
        #   vars: @variables 
        # ).render()
      else
        console.log 'create ImageView'
        # @$el.append new ImageView( 
        #   model: model 
        #   vars: @variables 
        # ).render().el

    render: ->
      @


  class ImageView extends AreaView

  class ImageDjatokaView extends AreaView
    render: ->
      rendering = {}

      djatokaTileWidth = 256

      x = if @model.get('x')? then @model.get('x') else 0
      y = if @model.get('y')? then @model.get('y') else 0
      width = if @model.get('width')? then @model.get('width') else @variables.get("width") - x
      height = if @model.get('height')? then @model.get('height') else @variables.get("height") - x

      divWidth = @$el.width() || 1
      divHeight = @$el.height() || 1

      divScale = @variables.get("scale")
      imgScale = divScale

      innerContainer = $("<div></div>")
      @$el.append innerContainer

      $(innerContainer).css
        'overflow': 'hidden'
        'position': "absolute"
        'top': 0
        'left': '16px'

      imgContainer = $("<div></div>")
      $(innerContainer).append(imgContainer)

      # app.imageControls.setActive(true)

      baseURL = @model.get("service") + "?url_ver=Z39.88-2004&rft_id=" + @model.get("@id")
      tempBaseURL = baseURL.replace(/http:\/\/tiles2\.bodleian\.ox\.ac\.uk:8080\//, '/')

      # rendering.update = (item) ->

      zoomLevel = null

      # rendering.getZoom = -> zoomLevel
      # rendering.setZoom = (z) ->
      # rendering.setScale = (s) ->
      # rendering.getScale = -> divScale
      # rendering.getX = ->
      # rendering.setX = (x) ->
      # rendering.getY = ->
      # rendering.setY = (y) ->

      offsetX = 0
      offsetY = 0

      # rendering.setOffsetX = (x) ->
      # rendering.setOffsetY = (y) ->
      # rendering.getOffsetX = -> offsetX
      # rendering.getOffsetY = -> offsetY

      # rendering.remove = ->
      #   $(imgContainer).empty()

      $.ajax
        url: tempBaseURL + "&svc_id=info:lanl-repo/svc/getMetadata"
        success: (metadata) =>
          # original{Width,Height} are the size of the full jp2 image - the maximum resolution            
          originalWidth = Math.floor(metadata.width) || 1
          originalHeight = Math.floor(metadata.height) || 1
          imgScale = width / originalWidth
          # zoomLevels are how many different times we can divide the resolution in half
          zoomLevels = Math.floor(metadata.levels)
          # div{Width,Height} are the size of the HTML <div/> in which we are rendering the image
          divWidth = @$el.width() || 1
          divHeight = @$el.height() || 1
          #divScale = @variables.get("scale")
          # {x,y}Tiles are how many whole times we can tile the <div/> with tiles _djatokaTileWidth_ wide
          xTiles = Math.floor(originalWidth * divScale * Math.pow(2.0, zoomLevel) / djatokaTileWidth)
          yTiles = Math.floor(originalHeight * divScale * Math.pow(2.0, zoomLevel) / djatokaTileWidth)
          inDrag = false
          
          #mouseupHandler = (e) ->
          #  if inDrag
          #    e.preventDefault()
          #    inDrag = false
          #$(document).mouseup mouseupHandler
          #that.onDestroy? ->
          #  $(document).unbind 'mouseup', mouseupHandler

          startX = 0
          startY = 0
          startoffsetX = offsetX
          startoffsetY = offsetY
          # Initially, center the image in the view area
          offsetX = 0
          offsetY = 0
          baseZoomLevel = 0 # this is the amount needed to render full width of the div - can change with a window resize
          
          # if we want all of the image to show up on the screen, then we need to pick the zoom level that
          # is one step larger than the screen
          # so if image is 1024 px and we want to fit in 256 px, then image = 2^(n) * fit
          #xUnits * 2^8 = divWidth - divWidth % 2^8
          #xUnits * 2^(8+z) = originalWidth - originalWidth % 2^(8+z)
          recalculateBaseZoomLevel = =>
            divWidth = @$el.width() || 1
            if @variables.get("scale")? > 0
              baseZoomLevel = Math.max(0, Math.ceil(-Math.log( @variables.get("scale") * imgScale )/Math.log(2)))
              # app.imageControls.setMinZoom 0
              # app.imageControls.setMaxZoom zoomLevels - baseZoomLevel

          wrapWithImageReplacement = (cb) ->
            cb()
            currentZ = Math.ceil(zoomLevel + baseZoomLevel)
            $(imgContainer).find("img").each (idx, elm) ->
              img = $(elm)
              x = img.data 'x'
              y = img.data 'y'
              z = img.data 'z'
              if z != currentZ
                img.css
                  "z-index": -10
              else
                img.css
                  "z-index": 0

          # rendering.setZoom = (z) ->
          #   if z != zoomLevel
          #     _setZoom(z)
              # app.imageControls.setZoom(z)

          # rendering.setScale = (s) ->
          #   divScale = s
          #   $(innerContainer).css
          #     width: originalWidth * divScale * imgScale
          #     height: originalHeight * divScale * imgScale

          #   oldZoom = baseZoomLevel
          #   recalculateBaseZoomLevel()
          #   if oldZoom != baseZoomLevel
          #     zoomLevel = zoomLevel - baseZoomLevel + oldZoom
          #     if zoomLevel > zoomLevels - baseZoomLevel
          #       zoomLevel = zoomLevels - baseZoomLevel
          #     if zoomLevel < 0
          #       zoomLevel = 0

          #     wrapper = wrapWithImageReplacement
          #   else
          #     wrapper = (cb) -> cb()
          #   wrapper renderTiles

          # that.onDestroy? app.imageControls.events.onZoomChange.addListener rendering.setZoom

          updateImageControlPosition = ->
            # app.imageControls.setImgPosition
            #   topLeft: 
            #     x: offsetX * imgScale
            #     y: offsetY * imgScale


          recalculateBaseZoomLevel()

          tiles = []
          for i in [0..zoomLevels]
            tiles[i] = []

            # level 6 => zoomed in all the way - 1px = 1px
            # level 5 => zoomed in such that   - 2px in image = 1px on screen
            #http://tiles2.bodleian.ox.ac.uk:8080/adore-djatoka/resolver?url_ver=Z39.88-2004
            #&rft_id=http://shelleygodwinarchive.org/images/ox/ox-ms_abinger_c56-0005.jp2&svc_id=info:lanl-repo/svc/getRegion&svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000&svc.format=image/jpeg&svc.level=3&svc.region=0,2048,256,256
          imageURL = (x,y,z) ->
            # we want (x,y) to be the tiling for the screen -- it should be fairly constant, but should be
            # divided into 256x256 pixel tiles

            #
            # the tileWidth is the amount of space in the full size jpeg2000 image represented by the tile
            #
            tileWidth = Math.pow(2.0, zoomLevels - z) * djatokaTileWidth
            [ 
              baseURL
              "svc_id=info:lanl-repo/svc/getRegion"
              "svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000"
              "svc.format=image/jpeg"
              "svc.level=#{z}"
              "svc.region=#{y * tileWidth},#{x * tileWidth},#{djatokaTileWidth},#{djatokaTileWidth}"
            ].join("&")

          screenCenter = ->
            original2screen(offsetX , offsetY)

          # we want to map 256 pixels from the Djatoka server onto 128-256 pixels on our screen
          calcJP2KTileSize = ->
            Math.pow(2.0, zoomLevels - Math.ceil(zoomLevel + baseZoomLevel)) * djatokaTileWidth

          calcTileSize = ->
            Math.floor(Math.pow(2.0, zoomLevel) * divScale * imgScale * calcJP2KTileSize())

          # returns the screen coordinates for the top/left position of the screen tile at the (x,y) position
          # takes into account the center{X,Y} and zoom level
          screenCoords = (x, y) ->
            tileSize = calcTileSize()
            top = y * tileSize
            left = x * tileSize
            center = screenCenter()
            return {
              top: top + center.top
              left: left + center.left
            }

          original2screen = (ox, oy) ->
            return {
              left: ox * divScale * imgScale * Math.pow(2.0, zoomLevel)
              top: oy * divScale * imgScale * Math.pow(2.0, zoomLevel)
            }

          screen2original = (ox, oy) ->
            return {
              left: ox / divScale / imgScale / Math.pow(2.0, zoomLevel)
              top: oy / divScale / imgScale / Math.pow(2.0, zoomLevel)
            }

          # make sure we aren't too far right/left/up/down
          constrainCenter = ->
            # we don't want the top-left corner to move into the div space
            # we don't want the bottom-right corner to move into the div space
            changed = false
            if zoomLevel == 0
              changed = true unless offsetX == 0 and offsetY == 0
              offsetX = 0
              offsetY = 0
            else
              sizes = screen2original(divWidth, divHeight)
              if offsetX > 0
                changed = true
                offsetX = 0
              if offsetY > 0
                changed = true
                offsetY = 0
              if offsetX < -originalWidth + sizes.left
                changed = true
                offsetX = -originalWidth + sizes.left
              if offsetY < -originalHeight + sizes.top
                changed = true
                offsetY = -originalHeight + sizes.top
            changed

          # returns the width/height of the screen tile at the (x,y) position
          screenExtents = (x, y) ->
            tileSize = calcTileSize()
            # when at full zoom in, we're using djatokaTileWidth == tileSize
            jp2kTileSize = calcJP2KTileSize()

            if (x + 1) * jp2kTileSize > originalWidth
              width = originalWidth - x * jp2kTileSize
            else
              width = jp2kTileSize
            if (y + 1) * jp2kTileSize > originalHeight
              height = originalHeight - y * jp2kTileSize
            else
              height = jp2kTileSize

            scale = tileSize / jp2kTileSize

            return {
              width: Math.max(0, width * scale)
              height: Math.max(0, height * scale)
            }

          renderTile = (o) ->
            z = Math.ceil(zoomLevel + baseZoomLevel)                
            topLeft = screenCoords(o.x, o.y)
            heightWidth = screenExtents(o.x, o.y)

            if heightWidth.height == 0 or heightWidth.width == 0
              return

            # If we've already created the image at this zoom level, then we'll just use it and adjust the
            # size/position on the screen.
            if tiles[z]?[o.x]?[o.y]?
              imgEl = tiles[z][o.x][o.y]

            # If the image is off the view area, we just hide it.
            if topLeft.left + heightWidth.width < 0 or topLeft.left > divWidth or topLeft.top + heightWidth.height < 0 or topLeft.top > divHeight
              if imgEl?
                imgEl.hide()
              return # don't render the image if off the top of left

            # If we have a cached image, we make sure it isn't hidden.
            if imgEl?
              imgEl.show()
            else
              imgEl = $("<img></img>")
              $(imgContainer).append(imgEl)
              imgEl.attr
                'data-x': o.x
                'data-y': o.y
                'data-z': z
                border: 'none'
                src: imageURL(o.x, o.y, z)
              tiles[z] ?= []
              tiles[z][o.x] ?= []
              tiles[z][o.x][o.y] = imgEl

              do (imgEl) ->
                imgEl.bind 'mousedown', (evt) ->
                  if not inDrag
                    evt.preventDefault()

                    startX = null
                    startY = null
                    startoffsetX = offsetX
                    startoffsetY = offsetY
                    inDrag = true
                    # MITHgrid.mouse.capture (type) ->
                    #   e = this
                    #   switch type
                    #     when "mousemove"
                    #       if !startX? or !startY?
                    #         startX = e.pageX
                    #         startY = e.pageY
                    #       scoords = screen2original(startX - e.pageX, startY - e.pageY)
                    #       offsetX = startoffsetX - scoords.left
                    #       offsetY = startoffsetY - scoords.top
                    #       renderTiles()
                    #       updateImageControlPosition()

                    #     when "mouseup"
                    #       inDrag = false
                    #       MITHgrid.mouse.uncapture()

                imgEl.bind 'mousewheel DOMMouseScroll MozMousePixelScroll', (e) ->
                  e.preventDefault()
                  inDrag = false
                
                  x = e.originalEvent.offsetX + parseInt($(imgEl).css('left'), 10)
                  y = e.originalEvent.offsetY + parseInt($(imgEl).css('top'), 10)
                
                  # we want to change centerX/centerY so that scrollPoint is constant after the zoom
                  z = zoomLevel
                  oldOffsetX = offsetX
                  oldOffsetY = offsetY
                  scrollPoint = screen2original(x, y)
                  oldOffsetX -= scrollPoint.left
                  oldOffsetY -= scrollPoint.top
                  if z >= 0 and z <= zoomLevels - baseZoomLevel
                    setZoom (z + 1) * (1 + e.originalEvent.wheelDeltaY / 500) - 1
                    # we only update the cursor position if we're in the same zoomLevel as the image after zooming in/out
                    if $(imgEl).data('z') == Math.ceil(zoomLevel + baseZoomLevel) 
                      scrollPoint = screen2original(x, y)
                      oldOffsetX += scrollPoint.left
                      oldOffsetY += scrollPoint.top
                      offsetX = oldOffsetX
                      offsetY = oldOffsetY
                      renderTiles()

            imgEl.css
              position: 'absolute'
              top: topLeft.top
              left: topLeft.left
              width: heightWidth.width
              height: heightWidth.height

          renderTiles = =>
            divWidth = @$el.width() || 1
            divHeight = @$el.height() || 1
            if constrainCenter()
              updateImageControlPosition()

            # the tileSize is the size of the area tiled by the image. It should be between 1/2 and 1 times the djatokaTileWidth
            tileSize = calcTileSize()
            # xTiles and yTiles are how many of these tileSize tiles will cover the zoomed in image
            xTiles = Math.floor(originalWidth * divScale * imgScale * Math.pow(2.0, zoomLevel) / tileSize)
            yTiles = Math.floor(originalHeight * divScale * imgScale * Math.pow(2.0, zoomLevel) / tileSize)
            
            # x,y,width,height are in terms of canvas extents - not screen pixels
            # s gives us the conversion to screen pixels
            # for now, we're mapping full images, so we don't need to worry about offsets into the image
            # xTiles tells us how many tiles across
            # yTiles tells us how many tiles down    fit in the view window - e.g., when zoomed in

            for j in [0..yTiles]
              for i in [0..xTiles]
                renderTile 
                  x: i
                  y: j
                  tileSize: tileSize

          setZoom = (z) ->
            wrapper = (cb) -> cb()
            if z < 0
              z = 0
            if z > zoomLevels - baseZoomLevel
              z = zoomLevels - baseZoomLevel
            if z != zoomLevel
              if zoomLevel? and Math.ceil(z) != Math.ceil(zoomLevel)
                wrapper = wrapWithImageReplacement
              zoomLevel = z
              wrapper renderTiles
         
          setScale = (s) ->
            divScale = s
            $(innerContainer).css
              width: originalWidth * divScale * imgScale
              height: originalHeight * divScale * imgScale

            oldZoom = baseZoomLevel
            recalculateBaseZoomLevel()
            if oldZoom != baseZoomLevel
              zoomLevel = zoomLevel - baseZoomLevel + oldZoom
              if zoomLevel > zoomLevels - baseZoomLevel
                zoomLevel = zoomLevels - baseZoomLevel
              if zoomLevel < 0
                zoomLevel = 0

              wrapper = wrapWithImageReplacement
            else
              wrapper = (cb) -> cb()
            wrapper renderTiles

          setScale divScale

          # rendering.setOffsetX = (x) ->
          #   offsetX = x
          #   renderTiles()
          #   updateImageControlPosition()

          # rendering.setOffsetY = (y) ->
          #   offsetY = y
          #   renderTiles()
          #   updateImageControlPosition()

          # rendering.addoffsetX = (dx) ->
          #   rendering.setOffsetX offsetX + dx

          # rendering.addoffsetY = (dy) ->
          #   rendering.setOffsetY offsetY + dy

          # rendering.setZoom(0)
          zoomLevel = 0

      @

)()