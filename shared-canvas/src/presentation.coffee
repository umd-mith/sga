# # Presentations
SGAReader.namespace "Presentation", (Presentation) ->

  #
  # ## Presentation.TextContent
  #

  Presentation.namespace "TextContent", (TextContent) ->
    TextContent.initInstance = (args...) ->
      MITHGrid.Presentation.initInstance "SGA.Reader.Presentation.TextContent", args..., (that, container) ->
        options = that.options

        makeAnnoLens = (type) ->
          that.addLens type, (container, view, model, id) ->
            rendering = {}
            el = $("<span></span>")
            rendering.$el = el
            item = model.getItem id
            el.text item.text[0]
            el.addClass item.type.join(" ")
            el.attr "style", item.css?[0]
            $(container).append el
            rendering.remove = ->
              el.remove()
            rendering.update = (item) ->
              el.text item.text[0]
            rendering

        #
        # We expect an HTML container for this to which we can append
        # all of the text content pieces that belong to this container.
        # For now, we are dependent on the data store to retain the ordering
        # of items based on insertion order.
        #
        makeAnnoLens 'AdditionAnnotation'
        makeAnnoLens 'DeletionAnnotation'
        makeAnnoLens 'SearchAnnotation'
        makeAnnoLens 'LineAnnotation'
        makeAnnoLens 'Text'

        that.addLens 'LineBreak', (container, view, model, id) ->
          rendering = {}
          el = $("<br/>")
          rendering.$el = el
          $(container).append(el)

          rendering.remove = -> el.remove()
          rendering.update = (item) ->

          rendering

  #
  # ## Presentation.Zone
  #
  Presentation.namespace "Zone", (Zone) ->
    Zone.initInstance = (args...) ->
      # We expect container to be in the SVG image
      MITHGrid.Presentation.initInstance "SGA.Reader.Presentation.Zone", args..., (that, container) ->
        options = that.options
        svgRoot = options.svgRoot

        annoExpr = that.dataView.prepare(['!target'])

        that.addLens 'Image', (container, view, model, id) ->
          return unless 'Image' in (options.types || [])
          rendering = {}

          item = model.getItem id

          # If the viewbox has been removed because of the image viewer, restore it.
          svg = $(svgRoot.root())
          # jQuery won't modify the viewBox - using pure JS
          vb = svg.get(0).getAttribute("viewBox")

          if !vb?
            svgRoot.configure
              viewBox: "0 0 #{options.width} #{options.height}"

          svgImage = null
          if item.image?[0]? and svgRoot?
            x = if item.x?[0]? then item.x[0] else 0
            y = if item.y?[0]? then item.y[0] else 0
            width = if item.width?[0]? then item.width[0] else options.width - x
            height = if item.height?[0]? then item.height[0] else options.height - y
            svgImage = svgRoot.image(container, x, y, width, height, item.image?[0], {
              preserveAspectRatio: 'none'
            })

          rendering.update = (item) ->
            # do nothing for now - eventually, update image
            if item.image?[0]? and svgRoot?
              x = if item.x?[0]? then item.x[0] else 0
              y = if item.y?[0]? then item.y[0] else 0
              width = if item.width?[0]? then item.width[0] else options.width - x
              height = if item.height?[0]? then item.height[0] else options.height - y
              svgRoot.remove svgImage
              svgImage = svgRoot.image(container, x, y, width, height, item.image?[0], {
                preserveAspectRatio: 'none'
              })

          rendering.remove = ->
            if svgImage? and svgRoot?
              svgRoot.remove svgImage
          rendering

        that.addLens 'ImageViewer', (container, view, model, id) ->
          return unless 'Image' in (options.types || [])
          rendering = {}

          item = model.getItem id

          app = that.options.application()

          # Activate imageControls
          app.imageControls.setActive(true)

          # Djatoka URL is now hardcoded, it will eventually come from the manifest
          # when we figure out how to model it.
          djatokaURL = "http://localhost:8080/adore-djatoka/resolver" 
          imageURL = item.image[0]
          baseURL = djatokaURL + "?url_ver=Z39.88-2004&rft_id=" + imageURL

          po = org.polymaps

          # clean up svg root element to accommodate Polymaps.js
          svg = $(svgRoot.root())
          # jQuery won't modify the viewBox - using pure JS
          svg.get(0).removeAttribute("viewBox")

          g = svgRoot.group()

          map = po.map()
            .container(g)

          canvas = $(container).parent().get(0)

          toAdoratio = $.ajax
            datatype: "json"
            url: baseURL + '&svc_id=info:lanl-repo/svc/getMetadata'
            success: adoratio(canvas, baseURL, map)

          # wait for polymap to load image and update map, then...
          toAdoratio.then ->
            map.on 'zoom', ->
              app.imageControls.setZoom(map.zoom())
            
          
          rendering.update = (item) ->
            0 # do nothing for now - eventually, update image viewer?

          rendering.remove = ->
            app.imageControls.setActive(false)
            0 # eventually remove svg g#map
          rendering

        that.addLens 'ZoneAnnotation', (container, view, model, id) ->
          rendering = {}
          # we need to get the width/height from the item
          # based on what we're targeting
          zoneInfo = model.getItem id
          zoneContainer = null
          zoneContainer = document.createElementNS('http://www.w3.org/2000/svg', 'svg' )
          # pull start/end/width/height from constraint with a default of
          # the full surface
          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y
          $(zoneContainer).attr("x", x).attr("y", y).attr("width", width).attr("height", height)
          container.appendChild(zoneContainer)
          # apply position/transformations
          # based on zoneannotation info

          # TODO: position/size zoneContainer and set scaling
          zoneDataView = MITHGrid.Data.SubSet.initInstance
            dataStore: model
            expressions: [ '!target' ]
            #key: id

          zone = Zone.initInstance zoneContainer,
            types: options.types
            dataView: zoneDataView
            svgRoot: svgRoot
            application: options.application
            heigth: height
            width: width

          zoneDataView.setKey id

          rendering._destroy = ->
            zone._destroy() if zone._destroy?
            zoneDataView._destroy() if zoneDataView._destroy?

          rendering.remove = ->
            #if svgRoot? and container?
            #  $(container).empty()
            #  svgRoot.remove container
            rendering._destroy()
 
          rendering.update = (item) ->
            x = if item.x?[0]? then item.x[0] else 0
            y = if item.y?[0]? then item.y[0] else 0
            width = if item.width?[0]? then item.width[0] else options.width - x
            height = if item.height?[0]? then item.height[0] else options.height - y
            $(zoneContainer).attr("x", x).attr("y", y).attr("width", width).attr("height", height)
 
          rendering

        that.addLens 'TextContent', (container, view, model, id) ->
          return unless 'Text' in (options.types || [])

          rendering = {}
          
          app = options.application()
          zoom = app.imageControls.getZoom()

          item = model.getItem id

          textContainer = null
          textContainer = document.createElementNS('http://www.w3.org/2000/svg', 'foreignObject' )
          # pull start/end/width/height from constraint with a default of
          # the full surface
          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y
          $(textContainer).attr("x", x).attr("y", y).attr("width", width).attr("height", height)
          container.appendChild(textContainer)

          bodyEl = document.createElementNS('http://www.w3.org/1999/xhtml', 'body')
          rootEl = document.createElement('div')
          $(rootEl).addClass("text-content")
          $(rootEl).attr("id", id)
          $(rootEl).css("font-size", 150)
          $(rootEl).css("line-height", 1.15)
          bodyEl.appendChild(rootEl)
          textContainer.appendChild(bodyEl)

          if app.imageControls.getActive()
            app.imageControls.events.onZoomChange.addListener (z)->
              console.log 'Zoom!'

          textDataView = MITHGrid.Data.SubSet.initInstance
            dataStore: model
            expressions: [ '!target' ]
            #key: id


          text = Presentation.TextContent.initInstance rootEl,
            types: options.types
            dataView: textDataView
            svgRoot: svgRoot
            application: options.application
            height: height
            width: width

          textDataView.setKey id

          rendering._destroy = ->
            text._destroy() if text._destroy?
            textDataView._destroy() if textDataView._destroy?

          rendering.remove = ->
            #$(textContainer).empty()
            #svgRoot.remove textContainer

          rendering.update = (item) ->
            x = if item.x?[0]? then item.x[0] else 0
            y = if item.y?[0]? then item.y[0] else 0
            width = if item.width?[0]? then item.width[0] else options.width - x
            height = if item.height?[0]? then item.height[0] else options.height - y
            $(textContainer).attr("x", x).attr("y", y).attr("width", width).attr("height", height)

          rendering

  #
  # ## Presentation.Canvas
  #
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

        highlightDS = null

        annoExpr = that.dataView.prepare(['!target'])

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
        SVGWidth = parseInt($(container).width()*20/20, 10)
        MITHGrid.events.onWindowResize.addListener ->
          SVGWidth = parseInt($(container).width() * 20/20, 10)
          if canvasWidth? and canvasWidth > 0
            that.setScale (SVGWidth / canvasWidth)
          

        that.events.onScaleChange.addListener (s) ->
          if canvasWidth? and canvasHeight?
            SVGHeight = parseInt(canvasHeight * s, 10)
            SVG (svgRoot) ->
              svgRootEl.attr
                width: canvasWidth
                height: canvasHeight
                #transform: "scale(#{s})"
              svgRoot.configure
                #transform: "scale(#{s})"
                viewBox: "0 0 #{canvasWidth} #{canvasHeight}"

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

        realCanvas = null

        that.events.onCanvasChange.addListener (canvas) ->
          dataView.setKey(canvas)
          item = dataView.getItem canvas
          # now make SVG canvas the size of the canvas (for now)
          # eventually, we'll constrain the size but maintain the
          # aspect ratio
          canvasWidth = item.width?[0] || 1
          canvasHeight = item.height?[0] || 1
          that.setScale (SVGWidth / canvasWidth)
          if realCanvas?
            realCanvas.hide() if realCanvas.hide?
            realCanvas._destroy() if realCanvas._destroy?
          SVG (svgRoot) ->
            svgRoot.clear()
            realCanvas = SGA.Reader.Presentation.Zone.initInstance svgRoot.root(),
              types: options.types
              dataView: dataView
              application: options.application
              height: canvasHeight
              width: canvasWidth
              svgRoot: svgRoot

