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
      MITHgrid.Presentation.initInstance "SGA.Reader.Presentation.TextContent", args..., (that, container) ->
        options = that.options

        that.setHeight 0

        that.events.onWidthChange.addListener (w) ->
          $(container).attr('width', w/10)

        if options.width?
          that.setWidth options.width
        if options.x?
          that.setX options.x
        if options.y?
          that.setY options.y

        #
        # We draw each text span type the same way. We rely on the
        # item.type to give us the CSS classes we need for the span
        #
        heightSettingTimer = null
        adjustHeight = ->
          if heightSettingTimer?
            clearTimeout heightSettingTimer
          heightSettingTimer = setTimeout ->
            h = $(container).height() * 10
            if h > options.height
              that.setHeight h
            else if h < options.height
              that.setHeight options.height
            heightSettingTimer = null
          , 0

        lines = {}
        currentLine = 0

        that.startDisplayUpdate = ->
          lines = {}
          currentLine = 0

        that.finishDisplayUpdate = ->
          $(container).empty()
          # now we go through the lines and push them into the dom
          currentLineEl = $("<div></div>")
          $(container).append(currentLineEl)
          afterLayout = []
          for lineNo in ((i for i of lines).sort (a,b) -> a - b)
            currentPos = 0
            for r in lines[lineNo]
              do (r) ->
                if r.$el?
                  if r.positioned
                    # TODO: fix the width calculation to something a bit smarter - this gets us a bit closer for now
                    #spanEl = $("<span style='display:inline-block;'></span>")
                    #$(container).append(spanEl)
                    currentPos = r.charLead
                    afterLayout.push r.afterLayout
                    # r.afterLayout spanEl
                  $(currentLineEl).append(r.$el)
                  r.$el.attr('data-pos', currentPos)
                  r.$el.attr('data-line', lineNo)
                  currentPos += (r.charWidth or 0)
            #$(currentLineEl).append("<br />")
            currentLineEl = $("<div></div>")
            $(container).append(currentLineEl)
          runAfterLayout = (i) ->
            if i < afterLayout.length
              afterLayout[i]()
              setTimeout (-> runAfterLayout(i+1)), 0
            # else
            #   h = $(container).height() * 10
            #   if h > options.height
            #     that.setHeight h
            #   else if h < options.height
            #     that.setHeight options.height()
          setTimeout ->
            runAfterLayout 0
          , 0
          adjustHeight()
          null

        renderingTimer = null
        that.eventModelChange = ->
          if renderingTimer?
            clearTimeout renderingTimer
          renderingTimer = setTimeout that.selfRender, 0

        annoLens = (container, view, model, id) ->
          rendering = {}
          el = $("<span></span>")
          rendering.$el = el
          item = model.getItem id
          el.text item.text[0]
          el.addClass item.type.join(" ")
          if item.css? and not /^\s*$/.test(item.css) then el.attr "style", item.css[0]
          
          
          content = item.text[0].replace(/\s+/g, " ")
          if content == " "
            rendering.charWidth = 0
          else
            rendering.charWidth = content.length

          if rendering.charWidth == 0
            return null

          lines[currentLine] ?= []
          lines[currentLine].push rendering
          rendering.line = currentLine
          rendering.positioned = false
          rendering.afterLayout = ->

          rendering.remove = ->
            el.remove()
            lines[rendering.line] = (r for r in lines[rendering.line] when r != rendering)
            adjustHeight()

          rendering.update = (item) ->
            el.text item.text[0]
            adjustHeight()

          rendering

        additionLens = (container, view, model, id) ->
          rendering = {}
          el = $("<span></span>")
          rendering.$el = el
          item = model.getItem id
          el.text item.text[0]
          el.addClass item.type.join(" ")
          #if item.css? and not /^\s*$/.test(item.css) then el.attr "style", item.css[0]
          if item.css? and /vertical-align: sub;/.test(item.css[0])
            ourLineNo = currentLine + 0.3
          else if item.css? and /vertical-align: super;/.test(item.css[0])
            ourLineNo = currentLine - 0.3
          else
            ourLineNo = currentLine
          lines[ourLineNo] ?= []
          lines[ourLineNo].push rendering
          lastRendering = lines[currentLine]?[lines[currentLine]?.length-1]
          rendering.positioned = currentLine != ourLineNo and lines[currentLine]?.length > 0
          content = item.text[0].replace(/\s+/g, " ")
          if content == " "
            rendering.charWidth = 0
          else
            rendering.charWidth = content.length
          rendering.line = ourLineNo
          rendering.afterLayout = ->
            if lastRendering?
              myOffset = rendering.$el.offset()
              middle = lastRendering.$el.offset().left + lastRendering.$el.outerWidth()/2
              myMiddle = myOffset.left + rendering.$el.outerWidth()/2
              neededSpace = middle - myMiddle
              # now we need to make sure we aren't overlapping with other text - if so, move to the right
              prevSibling = rendering.$el.prev()
              if prevSibling? and prevSibling.size() > 0
                prevOffset = prevSibling.offset()
                #if Math.abs(prevOffset.top - myOffset.top) < 5
                spacing = (prevOffset.left + prevSibling.outerWidth()) - myOffset.left 
                if spacing > neededSpace
                  neededSpace = spacing
              if neededSpace >= 0
                rendering.$el.css
                  'position': 'relative'
                  'left': (neededSpace) + "px"


          rendering.remove = ->
            el.remove()
            lines[rendering.line] = (r for r in lines[rendering.line] when r != rendering)
            adjustHeight()

          rendering.update = (item) ->
            el.text item.text[0]
            adjustHeight()

          rendering

        # Todo: add method to MITHgrid presentations to retrieve lens for a particular key
        #       that will let us eliminate the lenses variable and addLens redefinition here
        lenses = {}

        that.addLens = (key, lens) ->
          lenses[key] = lens

        that.getLens = (id) ->
          item = that.dataView.getItem id
          types = []
          for t in item.type
            if $.isArray(t)
              types = types.concat t
            else
              types.push t

          if 'AdditionAnnotation' in types
            return { render: lenses['AdditionAnnotation'] }

          for t in types
            if t != 'LineAnnotation' and lenses[t]?
              return { render: lenses[t] }
          return { render: lenses['LineAnnotation'] }

        that.hasLens = (k) -> lenses[k]?


        #
        # We expect an HTML container for this to which we can append
        # all of the text content pieces that belong to this container.
        # For now, we are dependent on the data store to retain the ordering
        # of items based on insertion order. Eventually, we'll build
        # item ordering into the basic MITHgrid presentation code. Then, we
        # can set 
        #
        that.addLens 'AdditionAnnotation', additionLens
        that.addLens 'DeletionAnnotation', annoLens
        that.addLens 'SearchAnnotation', annoLens
        that.addLens 'LineAnnotation', annoLens
        that.addLens 'Text', -> #annoLens

        #
        # Line breaks are different. We just want to add an explicit
        # break without any classes or styling.
        #
        that.addLens 'LineBreak', (container, view, model, id) ->
          currentLine += 1

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
      MITHgrid.Presentation.initInstance "SGA.Reader.Presentation.Zone", args..., (that, container) ->
        options = that.options
        svgRoot = options.svgRoot

        app = that.options.application()

        that.setHeight options.height
        that.setWidth options.width
        that.setX options.x
        that.setY options.y

        recalculateHeightTimer = null
        recalculateHeight = (h) ->
          if recalculateHeightTimer?
            clearTimeout recalculateHeightTimer
          heightSettingTimer = setTimeout ->
            length = (h or 0)
            that.visitRenderings (id) ->
              r = that.renderingFor id
              if r.getHeight?
                h = (r.getHeight() or 0)
              if r.getY?
                h += (r.getY() or 0)
              if h > length
                length = h
              true
            that.setHeight length + 15
          , 0

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

          # If the viewbox has been removed because of the image viewer, restore it.
          svg = $(svgRoot.root())
          # jQuery won't modify the viewBox - using pure JS
          vb = svg.get(0).getAttribute("viewBox")

          if !vb?
            svgRoot.configure
              viewBox: "0 0 #{options.width} #{options.height}"

          svgImage = null
          height = 0
          y = 0
          renderImage = (item) ->
            if item.image?[0]? and svgRoot?
              x = if item.x?[0]? then item.x[0] else 0
              y = if item.y?[0]? then item.y[0] else 0
              width = if item.width?[0]? then item.width[0] else options.width - x
              height = if item.height?[0]? then item.height[0] else options.height - y
              if svgImage?
                svgRoot.remove svgImage
              svgImage = svgRoot.image(container, x/10, y/10, width/10, height/10, item.image?[0], {
                preserveAspectRatio: 'none'
              })

          renderImage(item)

          rendering.getHeight = -> height/10

          rendering.getY = -> y/10

          rendering.update = renderImage

          rendering.remove = ->
            if svgImage? and svgRoot?
              svgRoot.remove svgImage
          rendering

        that.addLens 'ImageViewer', (container, view, model, id) ->
          return unless 'Image' in (options.types || [])
          rendering = {}

          item = model.getItem id

          

          # Activate imageControls
          app.imageControls.setActive(true)
          
          # Djatoka URL is now hardcoded, it will eventually come from the manifest
          # when we figure out how to model it.
          djatokaURL = "http://sga.mith.org:8080/adore-djatoka/resolver" 
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
            # Help decide when to propagate changes...
            fromZoomControls = false
            # Keep track of some start values
            startCenter = map.center()

            # Add listeners for external controls
            app.imageControls.events.onZoomChange.addListener (z) ->
              map.zoom(z)
              app.imageControls.setImgPosition map.position
              fromZoomControls = true
              
            app.imageControls.events.onImgPositionChange.addListener (p) ->
              # only apply if reset
              if p.topLeft.x == 0 and p.topLeft.y == 0
                map.center(startCenter)

            # Update controls with zoom and position info:
            # both at the beginning and after every change.
            app.imageControls.setZoom map.zoom()
            app.imageControls.setMaxZoom map.zoomRange()[1]
            app.imageControls.setMinZoom map.zoomRange()[0]
            app.imageControls.setImgPosition map.position
            
            map.on 'zoom', ->
              if !fromZoomControls
                app.imageControls.setZoom map.zoom()
                app.imageControls.setImgPosition map.position                
                app.imageControls.setMaxZoom map.zoomRange()[1]
              fromZoomControls = false
            map.on 'drag', ->
              app.imageControls.setImgPosition map.position

          # for now, this is the full height of the underlying canvas/zone
          rendering.getHeight = -> options.height/10

          rendering.getY = -> options.y / 10

          rendering.update = (item) ->
            0 # do nothing for now - eventually, update image viewer?

          rendering.remove = ->
            app.imageControls.setActive(false)
            app.imageControls.setZoom(0)
            app.imageControls.setMaxZoom(0)
            app.imageControls.setMinZoom(0)
            app.imageControls.setImgPosition 
              topLeft:
                x: 0,
                y: 0,
              bottomRight:
                x: 0,
                y: 0
            $(svgRoot.root()).find('#map').remove()

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
          container.appendChild(zoneContainer)

          # pull start/end/width/height from constraint with a default of
          # the full surface
          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y

          # TODO: position/size zoneContainer and set scaling.
          zoneDataView = MITHgrid.Data.SubSet.initInstance
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

          zone.events.onHeightChange.addListener (h) -> $(zoneContainer).attr('height', h/10)
          zone.events.onWidthChange.addListener (w) -> $(zoneContainer).attr('width', w/10)
          zone.events.onXChange.addListener (x) -> $(zoneContainer).attr('x', x/10)
          zone.events.onYChange.addListener (y) -> $(zoneContainer).attr('y', y/10)


          zone.setX x
          zone.setY y
          zone.setHeight height
          zone.setWidth width


          zone.events.onHeightChange.addListener recalculateHeight

          rendering.getHeight = zone.getHeight

          rendering.getY = zone.getY

          rendering._destroy = ->
            zone._destroy() if zone._destroy?
            zoneDataView._destroy() if zoneDataView._destroy?

          rendering.remove = ->
            zone.setHeight(0)
            $(zoneContainer).hide()
            rendering._destroy()
 
          rendering.update = (item) ->
            x = if item.x?[0]? then item.x[0] else 0
            y = if item.y?[0]? then item.y[0] else 0
            width = if item.width?[0]? then item.width[0] else options.width - x
            height = if item.height?[0]? then item.height[0] else options.height - y
            if height < zone.getHeight()
              height = zone.getHeight()
            that.setX x
            that.setY y
            that.setWidth width
            that.setHeight height
 
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
         
          $(textContainer).attr("x", x/10).attr("y", y/10).attr("width", width/10).attr("height", height/10)
          container.appendChild(textContainer)
          bodyEl = document.createElementNS('http://www.w3.org/1999/xhtml', 'body')
          overflowDiv = document.createElement('div')
          bodyEl.appendChild overflowDiv
          rootEl = document.createElement('div')
          $(rootEl).addClass("text-content")
          overflowDiv.appendChild rootEl
          
          rootEl.text(item.text[0])
          rendering.getHeight = -> $(textContainer).height() * 10

          rendering.getY = -> $(textContainer).position().top * 10

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
        # We have code to expand the overall canvas size for a Text-based div
        # if the text is too long for the view.
        #
        that.addLens 'TextContentZone', (container, view, model, id) ->
          return unless 'Text' in (options.types || [])

          # Set initial viewbox
          svg = $(svgRoot.root())
          # jQuery won't modify the viewBox - using pure JS
          #vb = svg.get(0).getAttribute("viewBox")

          #if !vb?
          #  svgRoot.configure
          #    viewBox: "0 0 #{options.width} #{options.height}"

          rendering = {}
          
          app = options.application()
          zoom = app.imageControls.getZoom()

          item = model.getItem id
 
          #
          # The foreignObject element MUST be in the SVG namespace, so we
          # can't use the jQuery convenience methods.
          #

          textContainer = null
          textContainer = document.createElementNS('http://www.w3.org/2000/svg', 'foreignObject' )
          textContainer.style.overflow = 'hidden'
          container.appendChild(textContainer)

          #
          # Similar to foreignObject, the body element MUST be in the XHTML
          # namespace, so we can't use jQuery. Once we're inside the body
          # element, we can use jQuery all we want.
          #
          bodyEl = document.createElementNS('http://www.w3.org/1999/xhtml', 'body')
          overflowDiv = document.createElement('div')
          #overflowDiv.style.overflow = 'hidden'
          bodyEl.appendChild overflowDiv
          rootEl = document.createElement('div')
          $(rootEl).addClass("text-content")
          $(rootEl).attr("id", id)
          $(rootEl).css("font-size", 15.0)
          $(rootEl).css("line-height", 1.15)
          overflowDiv.appendChild(rootEl)
          textContainer.appendChild(bodyEl)


          #
          # textDataView gives us all of the annotations targeting this
          # text content annotation - that is, all of the highlights and such
          # that change how we render the text mapped onto the zone/canvas.
          # We don't set the key here because the SubSet data view won't use
          # the key to filter the set of annotations during the initInstance
          # call.
          #
          textDataView = MITHgrid.Data.SubSet.initInstance
            dataStore: model
            expressions: [ '!target' ]

          #
          # If we're not given an offset and size, then we assume that we're
          # covering the entire targeted zone or canvas.
          #
          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y

          $(textContainer).attr("x", x/10).attr("y", y/10).attr("width", width/10).attr("height", height/10)

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
            x: x
            y: y

          #
          # Once we have the presentation in place, we set the
          # key of the SubSet data view to the id of the text content 
          # annotation item. This causes the presentation to render the
          # annotations.
          #
          textDataView.setKey id
          
          updateMarque = (z) ->

          if app.imageControls.getActive()
            # If the marquee already exists, replace it with a new one.
            $('.marquee').remove()
            # First time, always full extent in size and visible area
            strokeW = 1
            marquee = svgRoot.rect(0, 0, Math.max(1, that.getWidth()/10), Math.max(1, that.getHeight()/10),
              class : 'marquee' 
              fill: 'yellow', 
              stroke: 'navy', 
              strokeWidth: strokeW,
              fillOpacity: '0.05',
              strokeOpacity: '0.9' #currently not working in firefox
              )
            scale = that.getWidth() / 10 / $(container).width()
            visiblePerc = 100

            updateMarque = (z) ->
              if app.imageControls.getMaxZoom() > 0
                width  = Math.round(that.getWidth() / Math.pow(2, (app.imageControls.getMaxZoom() - z)))
                visiblePerc = Math.min(100, ($(container).width() * 100) / (width))

                marquee.setAttribute("width", (that.getWidth()/10 * visiblePerc) / 100 )
                marquee.setAttribute("height", (that.getHeight()/10 * visiblePerc) / 100 )

                if app.imageControls.getZoom() > app.imageControls.getMaxZoom() - 1
                  $(marquee).attr "opacity", "0"
                else
                  $(marquee).attr "opacity", "100"

            that.onDestroy app.imageControls.events.onZoomChange.addListener updateMarque

            that.onDestroy app.imageControls.events.onImgPositionChange.addListener (p) ->
              marquee.setAttribute("x", ((-p.topLeft.x * visiblePerc) / 100) * scale)
              marquee.setAttribute("y", ((-p.topLeft.y * visiblePerc) / 100) * scale)

          that.onDestroy text.events.onHeightChange.addListener (h) ->
            $(textContainer).attr("height", h/10)
            $(overflowDiv).attr("height", h/10)
            recalculateHeight()
            setTimeout (-> updateMarque app.imageControls.getZoom()), 0

          rendering.getHeight = text.getHeight

          rendering.getY = text.getY

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
            if height > that.getHeight()
              that.setHeight height
            else
              height = that.getHeight()
           
            $(textContainer).attr("x", x/10).attr("y", y/10).attr("width", width/10)

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
      MITHgrid.Presentation.initInstance "SGA.Reader.Presentation.Canvas", args..., (that, container) ->
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

        setSizeAttrs = ->
          SVG (svgRoot) ->

            svg = $(svgRoot.root())
            vb = svg.get(0).getAttribute("viewBox")

            if vb?
              svgRoot.configure
                viewBox: "0 0 #{canvasWidth/10} #{canvasHeight/10}"
            svgRootEl.css
              width: SVGWidth
              height: SVGHeight
              border: "1px solid #eeeeee"
              "border-radius": "2px"
              "background-color": "#ffffff"

        that.events.onHeightChange.addListener (h) ->
          SVGHeight = parseInt(SVGWidth / canvasWidth * canvasHeight, 10)

          if "Text" in options.types and h/10 > SVGHeight
            SVGHeight = h / 10
          setSizeAttrs()

        #
        # MITHgrid makes available a global listener for browser window
        # resizing so we don't have to guess how to do this for each
        # application.
        #
        MITHgrid.events.onWindowResize.addListener ->
          SVGWidth = parseInt($(container).width() * 20/20, 10)
          if canvasWidth? and canvasWidth > 0
            that.setScale (SVGWidth / canvasWidth)
          

        that.events.onScaleChange.addListener (s) ->
          if canvasWidth? and canvasHeight?
            SVGHeight = parseInt(canvasHeight * s, 10)
            setSizeAttrs()

        # the data view is managed outside the presentation
        dataView = MITHgrid.Data.SubSet.initInstance
          dataStore: options.dataView
          expressions: [ '!target' ]
          key: null

        realCanvas = null

        $(container).on "resetPres", ->    
          SVGWidth = parseInt($(container).width() * 20/20, 10)
          if canvasWidth? and canvasWidth > 0
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

        that.events.onCanvasChange.addListener (canvas) ->
          dataView.setKey(canvas)
          item = dataView.getItem canvas
          # now make SVG canvas the size of the canvas (for now)
          # eventually, we'll constrain the size but maintain the
          # aspect ratio
          canvasWidth = (item.width?[0] || 1)
          canvasHeight = (item.height?[0] || 1)
          that.setScale (SVGWidth / (canvasWidth))
          if realCanvas?
            realCanvas.hide() if realCanvas.hide?
            realCanvas._destroy() if realCanvas._destroy?
          SVG (svgRoot) ->
            # Trigger for slider height. There probably is a better way of passing this info around.
            $(container).trigger("sizeChange", [{w:container.width(), h:container.height()}]) 

            svgRoot.clear()
            realCanvas = SGA.Reader.Presentation.Zone.initInstance svgRoot.root(),
              types: options.types
              dataView: dataView
              application: options.application
              height: canvasHeight
              width: canvasWidth
              svgRoot: svgRoot
            that.setHeight canvasHeight
            realCanvas.events.onHeightChange.addListener that.setHeight


