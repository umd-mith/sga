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

        console.log that

        that.addLens 'Image', (container, view, model, id) ->
          return unless 'Image' in (options.types || [])
          rendering = {}
          console.log "Rendering an image", id
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
