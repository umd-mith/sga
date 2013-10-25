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
        if options.height?
          that.setHeight options.height
        if options.scale?
          that.setScale options.scale

        if options.inHTML
          that.events.onScaleChange.addListener (s) ->
            #$(container).css
            #  position: 'absolute'
            #  left: parseInt(that.getX() * s, 10) + "px"
            #  top: parseInt(that.getY() * s, 10) + "px"
            #  width: parseInt(that.getWidth() * s, 10) + "px"
            #  height: parseInt(that.getHeight() * s, 10) + "px"
            r.setScale(s) for r in scaleSettings

          
        #
        # We draw each text span type the same way. We rely on the
        # item.type to give us the CSS classes we need for the span
        #
        lines = {}
        lineAlignments = {}
        lineIndents = {}
        scaleSettings = []
        currentLine = 0

        that.startDisplayUpdate = ->
          lines = {}
          currentLine = 0

        that.finishDisplayUpdate = ->
          $(container).empty()
          # now we go through the lines and push them into the dom          
          afterLayout = []
          for lineNo in ((i for i of lines).sort (a,b) -> a - b)
            currentLineEl = $("<div></div>")
            if lineAlignments[lineNo]?
              currentLineEl.css
                'text-align': lineAlignments[lineNo]
            if lineIndents[lineNo]?
              currentLineEl.css
              currentLineEl.css
                'padding-left': (lineIndents[lineNo] * 4)+"em"

            lineNoFraq = lineNo - parseInt(lineNo, 10)
            if lineNoFraq < 0
              lineNoFraq += 1
            if lineNoFraq > 0.5
              currentLineEl.addClass 'above-line'
            else if lineNoFraq > 0
              currentLineEl.addClass 'below-line'

            $(container).append(currentLineEl)
            currentPos = 0
            afterLayoutPos = 0
            for r in lines[lineNo]
              do (r) ->
                if r.setScale?
                  scaleSettings.push r
                if r.$el?
                  if r.positioned
                    currentPos = r.charLead
                    if afterLayout[afterLayoutPos]?
                      afterLayout[afterLayoutPos].push r.afterLayout
                    else
                      afterLayout[afterLayoutPos] = [ r.afterLayout ]
                  $(currentLineEl).append(r.$el)
                  r.$el.attr('data-pos', currentPos)
                  r.$el.attr('data-line', lineNo)
                  currentPos += (r.charWidth or 0)

          runAfterLayout = (i) ->
            if i < afterLayout.length
              fn() for fn in afterLayout[i]
              setTimeout (-> runAfterLayout(i+1)), 0
          setTimeout ->
            runAfterLayout 0
          , 0
          null

        renderingTimer = null
        that.eventModelChange = ->
          if renderingTimer?
            clearTimeout renderingTimer
          renderingTimer = setTimeout that.selfRender, 0

        annoLens = (container, view, model, id) ->
          rendering = {}
          el = $("<span style='display: inline-block'></span>")
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
          rendering.setScale = ->

          rendering.afterLayout = ->

          rendering.remove = ->
            el.remove()
            lines[rendering.line] = (r for r in lines[rendering.line] when r != rendering)

          rendering.update = (item) ->
            el.text item.text[0]

          rendering

        additionLens = (container, view, model, id) ->
          rendering = {}
          el = $("<span style='display: inline-block'></span>")
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

          rendering.setScale = ->
            # noop

          rendering.afterLayout = ->
            ourWidth = that.getWidth() / 10
            ourLeft = rendering.$el.parent().offset().left

            if lastRendering?
              myOffset = rendering.$el.offset()
              if lastRendering.$el.hasClass 'DeletionAnnotation'
                middle = lastRendering.$el.offset().left + lastRendering.$el.outerWidth()/2
              else
                middle = lastRendering.$el.offset().left + lastRendering.$el.outerWidth()
              myMiddle = myOffset.left + rendering.$el.outerWidth()/2
              neededSpace = middle - myMiddle
              # now we need to make sure we aren't overlapping with other text - if so, move to the right
              prevSibling = rendering.$el.prev()
              accOffset = 0
              spacing = 0
              if prevSibling? and prevSibling.size() > 0
                prevOffset = prevSibling.offset()
                accOffset = prevSibling.offset().left + prevSibling.outerWidth() - ourLeft
                spacing = (prevOffset.left + prevSibling.outerWidth()) - myOffset.left
                spacing = parseInt(prevSibling.css('left'), 10) or 0 #(prevOffset.left) - myOffset.left

                if spacing > neededSpace
                  neededSpace = spacing
              if neededSpace >= 0
                if neededSpace + (myOffset.left - ourLeft) + accOffset + rendering.$el.outerWidth() > ourWidth

                  neededSpace = ourWidth - (myOffset.left - ourLeft) - accOffset - rendering.$el.outerWidth()

              # if we need negative space, then we need to move to the left if we can
              if neededSpace < 0
                # we need to move some of the other elements on this line
                if !prevSibling? or prevSibling.size() <= 0
                  neededSpace = 0
                else
                  neededSpace = -neededSpace
                  prevSiblings = rendering.$el.prevAll()
                  availableSpace = 0
                  prevSiblings.each (i, x) ->
                    availableSpace += (parseInt($(x).css('left'), 10) or 0)
                  if prevSibling.size() > 0
                    availableSpace -= (prevSibling.offset().left - ourLeft + prevSibling.outerWidth())
                  if availableSpace > neededSpace
                    usedSpace = 0
                    prevSiblings.each (i, s) ->
                      oldLeft = parseInt($(s).css('left'), 10) or 0
                      if availableSpace > 0
                        useWidth = parseInt(oldLeft * (neededSpace - usedSpace) / availableSpace, 10)
                        $(s).css('left', (oldLeft - useWidth - usedSpace) + "px")
                        usedSpace += useWidth
                        availableSpace -= oldLeft

                    neededSpace = -neededSpace
                  else
                    prevSiblings.each (i, s) -> $(s).css('left', "0px")                      
                    neededSpace = 0
              if neededSpace > 0
                if prevSibling.size() > 0
                  if neededSpace < parseInt(prevSibling.css('left'), 10)
                    neededSpace = parseInt(prevSibling.css('left'), 10)
                rendering.$el.css
                    'position': 'relative'
                    'left': (neededSpace) + "px"
                rendering.left = neededSpace / that.getScale()
                rendering.setScale = (s) ->
                  rendering.$el.css
                    'left': parseInt(rendering.left * s, 10) + "px"


          rendering.remove = ->
            el.remove()
            lines[rendering.line] = (r for r in lines[rendering.line] when r != rendering)

          rendering.update = (item) ->
            el.text item.text[0]

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
          item = model.getItem id
          if item.sgatextAlignment?.length > 0
            lineAlignments[currentLine] = item.sgatextAlignment[0]
          if item.sgatextIndentLevel?.length > 0
            lineIndents[currentLine] = parseInt(item.sgatextIndentLevel[0], 10) or 0
          null

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
        that.setScale options.scale

        recalculateHeight = (h) ->
         

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

        #http://tiles2.bodleian.ox.ac.uk:8080/adore-djatoka/resolver?url_ver=Z39.88-2004&rft_id=http://shelleygodwinarchive.org/images/ox/ox-ms_abinger_c56-0005.jp2&svc_id=info:lanl-repo/svc/getRegion&svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000&svc.format=image/jpeg&svc.level=3&svc.region=0,0,256,256

        that.addLens 'ImageViewer2', (container, view, model, id) ->
          return unless 'Image' in (options.types || [])

          rendering = {}

          item = model.getItem id

          app.imageControls.setActive(true)

          baseURL = item.url[0]
          tempBaseURL = baseURL.replace(/http:\/\/tiles2\.bodleian\.ox\.ac\.uk:8080\//, 'http://dev.shelleygodwinarchive.org/')

          console.log(baseURL, tempBaseURL, $(container))

          rendering.update = (item) ->

          rendering.getZoom = ->
          rendering.setZoom = (z) ->

          rendering.getX = ->
          rendering.setX = (x) ->
          rendering.getY = ->
          rendering.setY = (y) ->


          $.ajax
            url: tempBaseURL + "&svc_id=info:lanl-repo/svc/getMetadata"
            success: (metadata) ->              
              originalWidth = parseInt(metadata.width, 10) || 1
              originalHeight = parseInt(metadata.height, 10) || 1
              zoomLevels = parseInt(metadata.levels, 10)
              divWidth = $(svgRoot.root()).parent().width() || 1
              divHeight = $(svgRoot.root()).parent().height() || 1
              zoomForFull = zoomLevels - Math.floor((Math.log(originalWidth) - Math.log(divWidth))/Math.log(2.0))
              xTiles = Math.ceil(divWidth / 256)
              yTiles = Math.ceil(divHeight / 256)
              console.log
                imageWidth: originalWidth
                imageHeight: originalHeight
                zoomLevels: zoomLevels
                divWidth: divWidth
                divHeight: divHeight
                originalZoom: zoomForFull
                xTiles: xTiles
                yTiles: yTiles
                tileWidth: Math.pow(2.0, zoomForFull)*256
                #http://tiles2.bodleian.ox.ac.uk:8080/adore-djatoka/resolver?url_ver=Z39.88-2004
                #&rft_id=http://shelleygodwinarchive.org/images/ox/ox-ms_abinger_c56-0005.jp2&svc_id=info:lanl-repo/svc/getRegion&svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000&svc.format=image/jpeg&svc.level=3&svc.region=0,2048,256,256
              imageURL = (x,y,z) ->
                # we want (x,y) to be the tiling for the screen -- it should be fairly constant, but should be
                # divided into 256x256 pixel tiles
                tileWidth = Math.pow(2.0, zoomForFull) * 256
                xx = x * tileWidth
                yy = y * tileWidth
                baseURL + "&svc_id=info:lanl-repo/svc/getRegion&svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000&svc.format=image/jpeg&svc.level=#{z}&svc.region=#{yy},#{xx},256,256"
                
              console.log imageURL(0,0,zoomForFull)
              console.log imageURL(1,0,zoomForFull)

          rendering

        that.addLens 'ImageViewer', (container, view, model, id) ->
          return unless 'Image' in (options.types || [])
          rendering = {}

          browserZoomLevel = parseInt(document.width / document.body.clientWidth * 100 - 100, 10)
          
          # this is temporary until we see if scaling the SVG to counter this will fix the issues
          # this appears to be an issue only on webkit-based browsers - Mozilla/Firefox handles the
          # zoom just fine

          if 'webkitRequestAnimationFrame' in window and browserZoomLevel != 0
            # we're zoomed in/out and may have problems
            if !$("#zoom-warning").size()
              $(container).parent().prepend("<p id='zoom-warning'></p>")
            if browserZoomLevel > 0
              $("#zoom-warning").text("Zooming in using your browser's controls will distort the facsimile image.")
            else
              $("#zoom-warning").text("Zooming out using your browser's controls will distort the facsimile image.")
          else
            $("#zoom-warning").remove()
          

          item = model.getItem id

          # Activate imageControls
          app.imageControls.setActive(true)

          baseURL = item.url[0]

          po = org.polymaps

          # clean up svg root element to accommodate Polymaps.js
          svg = $(svgRoot.root())
          # jQuery won't modify the viewBox - using pure JS
          svg.get(0).removeAttribute("viewBox")

          g = svgRoot.group()

          tempBaseURL = baseURL.replace(/http:\/\/tiles2\.bodleian\.ox\.ac\.uk:8080\//, 'http://dev.shelleygodwinarchive.org/')

          map = po.map()
            .container(g)

          canvas = $(container).parent().get(0)

          toAdoratio = $.ajax
            datatype: "json"
            url: tempBaseURL + '&svc_id=info:lanl-repo/svc/getMetadata'
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

          MITHgrid.events.onWindowResize.addListener ->
            # do something to make the image grow/shrink to fill the space
            map.resize()

          rendering.update = (item) ->
            0 # do nothing for now - eventually, update image viewer?

          rendering.remove = ->
            app.imageControls.setActive(false)
            app.imageControls.setZoom(0)
            app.imageControls.setMaxZoom(0)
            app.imageControls.setMinZoom(0)
            app.imageControls.setImgPosition 
              topLeft:
                x: 0
                y: 0
              bottomRight:
                x: 0
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
          $(bodyEl).attr('xmlns', "http://www.w3.org/1999/xhtml")

          overflowDiv = document.createElement('div')
          bodyEl.appendChild overflowDiv
          rootEl = document.createElement('div')
          $(rootEl).addClass("text-content")
          $(overflowDiv).css
            'overflow': 'auto'
            'height': height/10
            'width': width/10

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
          vb = svg.get(0).getAttribute("viewBox")

          if !vb?
            svgRoot.configure
              viewBox: "0 0 #{options.width} #{options.height}"

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
          textContainer.style.overflow = 'auto'
          container.appendChild(textContainer)

          #
          # Similar to foreignObject, the body element MUST be in the XHTML
          # namespace, so we can't use jQuery. Once we're inside the body
          # element, we can use jQuery all we want.
          #
          bodyEl = document.createElementNS('http://www.w3.org/1999/xhtml', 'body')
          $(bodyEl).attr('xmlns', "http://www.w3.org/1999/xhtml")
          overflowDiv = document.createElement('div')
          $(overflowDiv).css('overflow', 'auto')

          bodyEl.appendChild overflowDiv
          rootEl = document.createElement('div')
          $(rootEl).addClass("text-content")
          $(rootEl).attr("id", id)
          $(rootEl).css
            #"font-size": 15.0
            #"line-height": 1.15
            #"overflow": "auto"
            "white-space": "nowrap"
            "overflow": "auto"

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
          $(rootEl).css('width', width/10)
          $(overflowDiv).css
            'width': width/10
            'height': height/10

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
            scale: that.getScale()

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

          ###
          that.onDestroy text.events.onHeightChange.addListener (h) ->
            #$(textContainer).attr("height", h/10)
            #$(overflowDiv).attr("height", h/10)
            #recalculateHeight()
            #setTimeout (-> updateMarque app.imageControls.getZoom()), 0
          ###

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
            #if height > that.getHeight()
            #  that.setHeight height
            #else
            #  height = that.getHeight()
            that.setHeight height
            $(textContainer).attr("x", x/10).attr("y", y/10).attr("width", width/10)

          rendering

  Presentation.namespace "TextZone", (Zone) ->
    Zone.initInstance = (args...) ->
      MITHgrid.Presentation.initInstance "SGA.Reader.Presentation.TextZone", args..., (that, container) ->
        options = that.options
        svgRoot = options.svgRoot

        app = that.options.application()

        that.setHeight options.height
        that.setWidth options.width
        that.setX options.x
        that.setY options.y
        that.setScale options.scale

        updateMarque = (z) ->

        app = that.options.application()

        if app.imageControls?.getActive()
          # If the marquee already exists, replace it with a new one.
          $('.marquee').remove()
          # First time, always full extent in size and visible area
          strokeW = 1
          marquee = $("<div class='marquee'></div>")
          $(container).append(marquee)
          marquee.css
            "border-color": 'navy'
            "background-color": "yellow"
            "border-width": strokeW
            "opacity": "0.1"
            "border-opacity": "0.9"
            "width": options.width * options.scale
            "height": options.height * options.scale
            "position": "absolute"
            "z-index": 0
            "top": 0
            "left": 16

          visiblePerc = 100
          marqueeLeft = 0
          marqueeTop = 0
          marqueeWidth = parseInt((that.getWidth() * visiblePerc * that.getScale())/100, 10 )
          marqueeHeight = parseInt((that.getHeight() * visiblePerc * that.getScale())/100, 10 )

          # we do our own clipping because of the way margins and padding play with us

          updateMarque = (z) ->
            if app.imageControls.getMaxZoom() > 0
              width  = Math.round(that.getWidth() / Math.pow(2, (app.imageControls.getMaxZoom() - z)))
              visiblePerc = Math.min(100, ($(container).width() * 100) / (width))

              marqueeWidth = parseInt((that.getWidth() * visiblePerc * that.getScale())/100, 10 )
              marqueeHeight = parseInt((that.getHeight() * visiblePerc * that.getScale())/100, 10 )
              
              marquee.css
                "width":
                  if marqueeLeft < 0
                    marqueeWidth + marqueeLeft 
                  else if marqueeWidth + marqueeLeft > $(container).width() 
                    $(container).width() - marqueeLeft 
                  else marqueeWidth
                "height": 
                  if marqueeTop < 0  
                    marqueeHeight + marqueeTop 
                  else if marqueeHeight + marqueeTop > $(container).height()
                    $(container).height() - marqueeTop 
                  else 
                    marqueeHeight
              if app.imageControls.getZoom() > app.imageControls.getMaxZoom() - 1
                $(marquee).css "opacity", "0"
              else
                $(marquee).css "opacity", "0.1"

          that.onDestroy app.imageControls.events.onZoomChange.addListener updateMarque

          that.onDestroy app.imageControls.events.onImgPositionChange.addListener (p) ->
            marqueeLeft = parseInt( (-p.topLeft.x * visiblePerc / 10) * that.getScale(), 10)
            marqueeTop = parseInt( (-p.topLeft.y * visiblePerc / 10) * that.getScale(), 10)
            marquee.css({
              "left": 16 + Math.max(0, marqueeLeft)
              "top": Math.max(0, marqueeTop)
              "width":
                if marqueeLeft < 0
                  marqueeWidth + marqueeLeft 
                else if marqueeWidth + marqueeLeft > $(container).width() 
                  $(container).width() - marqueeLeft 
                else marqueeWidth
              "height": 
                if marqueeTop < 0  
                  marqueeHeight + marqueeTop 
                else if marqueeHeight + marqueeTop > $(container).height()
                  $(container).height() - marqueeTop 
                else 
                  marqueeHeight
            })

        that.events.onScaleChange.addListener (s) ->
          updateMarque(app.imageControls.getZoom())
          that.visitRenderings (id, r) ->
            r.setScale?(s)
            true

        #
        # !target gives us all of the annotations that target the given
        # item id. We use this later to find all of the annotations that target
        # a given zone.
        #
        annoExpr = that.dataView.prepare(['!target'])

        #
        # A ContentAnnotation is just text placed on the canvas. No
        # structure. This is the default mode for SharedCanvas.
        #
        # See the following TextContentZone lens for how we're managing
        # the SVG/HTML interface.
        #

        that.addLens 'ContentAnnotation', (innerContainer, view, model, id) ->
          rendering = {}
          item = model.getItem id

          textContainer = $("<div></div>")

          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y
          
          $(textContainer).css
            "position": "absolute"
            "left": parseInt(16 + x * that.getScale(), 10) + "px"
            "top": parseInt(y * that.getScale(), 10) + "px"
            "width": parseInt(width * that.getScale(), 10) + "px"
            "height": parseInt(height * that.getScale(), 10) + "px"

          container.append(textContainer)
          overflowDiv = $("<div></div>")
          container.append overflowDiv
          rootEl = $("<div></div>")
          $(rootEl).addClass("text-content")
          $(overflowDiv).css
            'overflow': 'auto'
            'height': parseInt(height * that.getScale(), 10) + "px"
            'width': parseInt(width * that.getScale(), 10) + "px"

          overflowDiv.append rootEl
          
          rootEl.text(item.text[0])
          rendering.getHeight = -> $(textContainer).height() * 10

          rendering.getY = -> $(textContainer).position().top * 10

          rendering.update = (item) ->
            rootEl.text(item.text[0])
          rendering.remove = ->
            rootEl.remove()
          rendering.setScale = (s) ->
            $(textContainer).css
              "left": parseInt(16 + x * s, 10) + "px"
              "top": parseInt(y * s, 10) + "px"
              "width": parseInt(width * s, 10) + "px"
              "height": parseInt(height * s, 10) + "px"
            $(overflowDiv).css
              'height': parseInt(height * that.getScale(), 10) + "px"
              'width': parseInt(width * that.getScale(), 10) + "px"
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
        that.addLens 'TextContentZone', (innerContainer, view, model, id) ->
          rendering = {}
          
          app = options.application()
          zoom = app.imageControls.getZoom()

          item = model.getItem id
 
          #
          # The foreignObject element MUST be in the SVG namespace, so we
          # can't use the jQuery convenience methods.
          #

          textContainer = $("<div></div>")
          textContainer.css
            overflow: 'auto'
            position: 'absolute'

          container.append(textContainer)

          #
          # Similar to foreignObject, the body element MUST be in the XHTML
          # namespace, so we can't use jQuery. Once we're inside the body
          # element, we can use jQuery all we want.
          #
          rootEl = $("<div></div>")
          $(rootEl).addClass("text-content")
          $(rootEl).attr("id", id)
          $(rootEl).css
            "white-space": "nowrap"

          textContainer.append(rootEl)


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

          $(textContainer).css
            left: parseInt(16 + x * that.getScale(), 10) + "px"
            top: parseInt(y * that.getScale(), 10) + "px"
            width: parseInt(width * that.getScale(), 10) + "px"
            height: parseInt(height * that.getScale(), 10) + "px"

          #
          # Here we embed the text-based zone within the pixel-based
          # zone. Any text-based positioning will have to be handled by
          # the TextContent presentation.
          #
          text = Presentation.TextContent.initInstance rootEl,
            types: options.types
            dataView: textDataView
            application: options.application
            height: height
            width: width
            x: x
            y: y
            scale: that.getScale()
            inHTML: true

          #
          # Once we have the presentation in place, we set the
          # key of the SubSet data view to the id of the text content 
          # annotation item. This causes the presentation to render the
          # annotations.
          #
          textDataView.setKey id

          rendering.getHeight = text.getHeight

          rendering.getY = text.getY

          rendering._destroy = ->
            text._destroy() if text._destroy?
            textDataView._destroy() if textDataView._destroy?

          rendering.remove = ->
            $(textContainer).empty()

          rendering.setScale = (s) ->
            $(textContainer).css
              left: parseInt(16 + x * s, 10) + "px"
              top: parseInt(y * s, 10) + "px"
              width: parseInt(width * s, 10) + "px"
              height: parseInt(height * s, 10) + "px"
            text.setScale s

          rendering.update = (item) ->
            x = if item.x?[0]? then item.x[0] else 0
            y = if item.y?[0]? then item.y[0] else 0
            width = if item.width?[0]? then item.width[0] else options.width - x
            height = if item.height?[0]? then item.height[0] else options.height - y
            #if height > that.getHeight()
            #  that.setHeight height
            #else
            #  height = that.getHeight()
            that.setHeight height
            $(textContainer).css
              left: parseInt(16 + x * that.getScale(), 10) + "px"
              top: parseInt(y * that.getScale(), 10) + "px"
              width: parseInt(width * that.getScale(), 10) + "px"
              height: parseInt(height * that.getScale(), 10) + "px"
          rendering

  #
  # ## Presentation.Canvas
  #

  # Selects one of TextCanvas or ImageCanvas as appropriate.

  Presentation.namespace "Canvas", (Canvas) ->
    Canvas.initInstance = (args...) ->
      [ ns, container, options ] = MITHgrid.normalizeArgs(args...)
      if "Text" in options.types and options.types.length == 1
        SGA.Reader.Presentation.TextCanvas.initInstance args...
      else
        SGA.Reader.Presentation.ImageCanvas.initInstance args...
  #
  # ## Presentation.TextCanvas
  #

  #
  # This is the wrapper around a root presentation that gets things started.
  # It handles things when 'Text' is the only presentation type (@data-types)
  #

  Presentation.namespace "TextCanvas", (Canvas) ->
    Canvas.initInstance = (args...) ->
      MITHgrid.Presentation.initInstance "SGA.Reader.Presentation.TextCanvas", args..., (that, container) ->
        # we're just going to be a div with positioned child divs
        options = that.options

        annoExpr = that.dataView.prepare(['!target'])

        viewEl = $("<div></div>")
        container.append(viewEl)

        canvasWidth = null
        canvasHeight = null

        baseFontSize = 150 # in terms of the SVG canvas size - about 15pt
        DivHeight = null
        DivWidth = parseInt($(container).width()*20/20, 10)
        $(container).height(parseInt($(container).width() * 4 / 3, 10))

        resizer = ->
          DivWidth = parseInt($(container).width()*20/20,10)
          if canvasWidth? and canvasWidth > 0
            that.setScale  DivWidth / canvasWidth

        MITHgrid.events.onWindowResize.addListener resizer

        $(viewEl).css
          'border': '1px solid grey'
          'background-color': 'white'

        that.events.onScaleChange.addListener (s) ->
          if canvasWidth? and canvasHeight?
            DivHeight = parseInt(canvasHeight * s, 10)
          $(viewEl).css
            'font-size': (parseInt(baseFontSize * s * 10, 10) / 10) + "px"
            'line-height': (parseInt(baseFontSize * s * 11.5, 10) / 10) + "px"
            'height': DivHeight
            'width': DivWidth
          realCanvas?.setScale s

        # the data view is managed outside the presentation
        dataView = MITHgrid.Data.SubSet.initInstance
          dataStore: options.dataView
          expressions: [ '!target' ]
          key: null

        realCanvas = null

        $(container).on "resetPres", ->
          resizer()
          if realCanvas?
            realCanvas.hide() if realCanvas.hide?
            realCanvas._destroy() if realCanvas._destroy?
          $(viewEl).empty()
          realCanvas = SGA.Reader.Presentation.TextZone.initInstance viewEl,
            types: options.types
            dataView: dataView
            application: options.application
            height: canvasHeight
            width: canvasWidth
            scale: DivWidth / canvasWidth

        that.events.onCanvasChange.addListener (canvas) ->
          dataView.setKey(canvas)
          item = dataView.getItem canvas
          
          canvasWidth = (item.width?[0] || 1)
          canvasHeight = (item.height?[0] || 1)
          resizer()
          if realCanvas?
            realCanvas.hide() if realCanvas.hide?
            realCanvas._destroy() if realCanvas._destroy?
        
          $(viewEl).empty()
          realCanvas = SGA.Reader.Presentation.TextZone.initInstance viewEl,
            types: options.types
            dataView: dataView
            application: options.application
            height: canvasHeight
            width: canvasWidth
            scale: DivWidth / canvasWidth
          that.setHeight canvasHeight
          realCanvas.events.onHeightChange.addListener that.setHeight

  #
  # ## Presentation.ImageCanvas
  #

  #
  # This is the wrapper around a root Zone presentation that gets things
  # started. It handles things when 'Image' is in the presentation type (@data-types)
  #
  Presentation.namespace "ImageCanvas", (Canvas) ->
    Canvas.initInstance = (args...) ->
      MITHgrid.Presentation.initInstance "SGA.Reader.Presentation.ImageCanvas", args..., (that, container) ->
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
        $(container).append(svgRootEl)
        try
          svgRoot = $(svgRootEl).svg 
            onLoad: (svg) ->
              SVG = (cb) -> cb(svg)
              cb(svg) for cb in pendingSVGfctns
              pendingSVGfctns = null
        catch e
          console.log "svg call failed:", e.message

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

          #if "Text" in options.types and h/10 > SVGHeight
          #  SVGHeight = h / 10
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
                scale: that.getScale()

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
              scale: that.getScale()
            that.setHeight canvasHeight
            realCanvas.events.onHeightChange.addListener that.setHeight
