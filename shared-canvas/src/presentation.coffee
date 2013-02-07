# # Presentations
SGAReader.namespace "Presentation", (Presentation) ->

  #
  # ## Presentation.TextContent
  #

  #
  # The TextContent presentation is all about modeling a section of a canvas
  # as a textual zone instead of a pixel-based zone. Eventually, we may want
  # to allow addressing of lines and character offsets, but for now we simply
  # fill in the area with textual annotations in the dataView.
  #

  Presentation.namespace "TextContent", (TextContent) ->
    TextContent.initInstance = (args...) ->
      MITHGrid.Presentation.initInstance "SGA.Reader.Presentation.TextContent", args..., (that, container) ->
        options = that.options

        #
        # We draw each text span type the same way. We rely on the
        # item.type to give us the CSS classes we need for the span
        #
        annoLens = (container, view, model, id) ->
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
        # of items based on insertion order. Eventually, we'll build
        # item ordering into the basic MITHGrid presentation code. Then, we
        # can set 
        #
        that.addLens 'AdditionAnnotation', annoLens
        that.addLens 'DeletionAnnotation', annoLens
        that.addLens 'LineAnnotation', annoLens
        that.addLens 'Text', annoLens

        #
        # Line breaks are different. We just want to add an explicit
        # break without any classes or styling.
        #
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

  #
  # The Zone presentation handles mapping annotations onto an SVG
  # surface. A Canvas is just a special zone that covers the entire canvas.
  #
  # We expect container to be in the SVG image.
  #
  Presentation.namespace "Zone", (Zone) ->
    Zone.initInstance = (args...) ->
      MITHGrid.Presentation.initInstance "SGA.Reader.Presentation.Zone", args..., (that, container) ->
        options = that.options
        svgRoot = options.svgRoot

        #
        # !target gives us all of the annotations that target the given
        # item id. We use this later to find all of the annotations that target
        # a given zone.
        #
        annoExpr = that.dataView.prepare(['!target'])

        #
        # Since images don't have annotations attached to them, we simply
        # do nothing if our presentation root isn't marked as including
        # images.
        #
        that.addLens 'Image', (container, view, model, id) ->
          return unless 'Image' in (options.types || [])
          rendering = {}

          item = model.getItem id

          svgImage = null
          renderImage = (item) ->
            if item.image?[0]? and svgRoot?
              x = if item.x?[0]? then item.x[0] else 0
              y = if item.y?[0]? then item.y[0] else 0
              width = if item.width?[0]? then item.width[0] else options.width - x
              height = if item.height?[0]? then item.height[0] else options.height - y
              if svgImage?
                svgRoot.remove svgImage
              svgImage = svgRoot.image(container, x, y, width, height, item.image?[0], {
                preserveAspectRatio: 'none'
              })

          renderImage(item)

          rendering.update = renderImage

          rendering.remove = ->
            if svgImage? and svgRoot?
              svgRoot.remove svgImage
          rendering

        #
        # ZoneAnnotations just map a zone onto a zone or canvas. We render
        # these regardless of what kinds of annotations we are displaying
        # since we might eventually get to an annotation we want to display.
        #
        that.addLens 'ZoneAnnotation', (container, view, model, id) ->
          rendering = {}

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

          # TODO: position/size zoneContainer and set scaling.
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
            rendering._destroy()
 
          rendering.update = (item) ->
            x = if item.x?[0]? then item.x[0] else 0
            y = if item.y?[0]? then item.y[0] else 0
            width = if item.width?[0]? then item.width[0] else options.width - x
            height = if item.height?[0]? then item.height[0] else options.height - y
            $(zoneContainer).attr("x", x).attr("y", y).attr("width", width).attr("height", height)
 
          rendering

        #
        # A ContentAnnotation is just text placed on the canvas. No
        # structure. This is the default mode for SharedCanvas.
        #
        # See the following TextContentZone lens for how we're managing
        # the SVG/HTML interface.
        #

        that.addLens 'ContentAnnotation', (container, view, model, id) ->
          return unless 'Text' in (options.types || [])

          rendering = {}
          item = model.getItem id

          textContainer = document.createElementNS('http://www.w3.org/2000/svg', 'foreignObject')

          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y
          $(textContainer).attr("x", x).attr("y", y).attr("width", width).attr("height", height)
          container.appendChild(textContainer)
          bodyEl = document.createElementNS('http://www.w3.org/1999/xhtml', 'body')
          rootEl = document.createElement('div')
          $(rootEl).addClass("text-content")
          
          rootEl.text(item.text[0])
          rendering.update = (item) ->
            rootEl.text(item.text[0])
          rendering.remove = ->
            rootEl.remove()
          rendering

        #
        #
        # We're rendering text content from here on down, so if we aren't
        # rendering text for this view, then we shouldn't do anything here.
        #
        # N.B.: If we ever support showing images based on their place
        # in the text, then we will need to treat this like we treat the
        # Zone above and allow rendering of embedded zones even if we don't
        # render the textual content.
        #
        that.addLens 'TextContentZone', (container, view, model, id) ->
          return unless 'Text' in (options.types || [])

          rendering = {}
          app = options.application()
          item = model.getItem id
 
          #
          # The foreignObject element MUST be in the SVG namespace, so we
          # can't use the jQuery convenience methods.
          #
          textContainer = document.createElementNS('http://www.w3.org/2000/svg', 'foreignObject' )

          #
          # If we're not given an offset and size, then we assume that we're
          # covering the entire targeted zone or canvas.
          #
          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y
          $(textContainer).attr("x", x).attr("y", y).attr("width", width).attr("height", height)
          container.appendChild(textContainer)

          #
          # Similar to foreignObject, the body element MUST be in the XHTML
          # namespace, so we can't use jQuery. Once we're inside the body
          # element, we can use jQuery all we want.
          #
          bodyEl = document.createElementNS('http://www.w3.org/1999/xhtml', 'body')
          rootEl = document.createElement('div')
          $(rootEl).addClass("text-content")
          $(rootEl).attr("id", id)
          $(rootEl).css("font-size", 150)
          $(rootEl).css("line-height", 1.15)
          bodyEl.appendChild(rootEl)
          textContainer.appendChild(bodyEl)

          #
          # textDataView gives us all of the annotations targeting this
          # text content annotation - that is, all of the highlights and such
          # that change how we render the text mapped onto the zone/canvas.
          # We don't set the key here because the SubSet data view won't use
          # the key to filter the set of annotations during the initInstance
          # call.
          #
          textDataView = MITHGrid.Data.SubSet.initInstance
            dataStore: model
            expressions: [ '!target' ]

          #
          # Here we embed the text-based zone within the pixel-based
          # zone. Any text-based positioning will have to be handled by
          # the TextContent presentation.
          #
          text = Presentation.TextContent.initInstance rootEl,
            types: options.types
            dataView: textDataView
            svgRoot: svgRoot
            application: options.application
            height: height
            width: width

          #
          # Once we have the presentation in place, we set the
          # key of the SubSet data view to the id of the text content 
          # annotation item. This causes the presentation to render the
          # annotations.
          #
          textDataView.setKey id

          rendering._destroy = ->
            text._destroy() if text._destroy?
            textDataView._destroy() if textDataView._destroy?

          rendering.remove = ->
            $(textContainer).empty()
            svgRoot.remove textContainer

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

  #
  # This is the wrapper around a root Zone presentation that gets things
  # started.
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

        #
        # MITHGrid makes available a global listener for browser window
        # resizing so we don't have to guess how to do this for each
        # application.
        #
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
              svgRoot.configure
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
