# # Presentations
SGAReader.namespace "Presentation", (Presentation) ->
  Presentation.namespace "Canvas", (Canvas) ->
    Canvas.initInstance = (args...) ->
      MITHGrid.Presentation.initInstance "SGA.Reader.Presentation.Canvas", args..., (that, container) ->
        # We want to draw everything that annotates a Canvas
        # this would be anything with a target = the canvas
        options = that.options

        pendingSVGfctns = []
        SVG = (cb) ->
          pendingSVGfctns.push cb

        svgRootEl = $("""
          <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
               xmlns:xlink="http://www.w3.org/1999/xlink"
               width="0" height="0" viewbG
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
        SVGWidth = $(container).width()*19/20
        SVGHeight = null
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

          # we need a nice way to get the span of text from the tei
          # and then we apply any annotations that modify how we display
          # the text before we create the svg elements - that way, we get
          # things like line breaks
          #
          # .target = tei.id AND
          # ( .start <= item.end[0] OR
          #   .end >= item.start[0] )
          #
          #highlightDS = MITHGrid.Data.RangePager.initInstance
          #  dataStore: MITHGrid.Data.View.initInstance
          #    dataStore: model
          #    type: ['LineAnnotation', 'DeleteAnnotation', 'AddAnnotation']
          #  leftExpressions: [ '.end' ]
          #  rightExpressions: [ '.start' ]

          # we also need to know when we have one of these annotations
          # getting updated - we might be able to hook into the
          # highlightDS object for this and leave the following
          # rendering.update method for tracking changes to the
          # underlying unstructured text range

          SVG (svgRoot) ->
            texts = svgRoot.createText()
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
                # now apply annotation to text

              #svgText = svgRoot.textpath(texts, "#textpath-#{id}", texts.string(text))
              #svgRoot.text(svgText)
              svgText = svgRoot.text(0, 100, text, { "font-size": "12pt" })

          rendering.update = (item) ->
            # do nothing for now
          rendering.remove = ->
            SVG (svgRoot) ->
              svgRoot.remove svgText
          rendering
