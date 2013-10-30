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
            #  left: Math.floor(that.getX() * s) + "px"
            #  top: Math.floor(that.getY() * s) + "px"
            #  width: Math.floor(that.getWidth() * s) + "px"
            #  height: Math.floor(that.getHeight() * s) + "px"
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
                'padding-left': (lineIndents[lineNo] * 1)+"em"

            lineNoFraq = lineNo - Math.floor(lineNo)
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
          runAfterLayout 0

        renderingTimer = null
        that.eventModelChange = ->
          if renderingTimer?
            clearTimeout renderingTimer
          renderingTimer = setTimeout ->
            that.selfRender()
            renderingTimer = null
          , 0

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
                spacing = Math.floor(prevSibling.css('left')) or 0 #(prevOffset.left) - myOffset.left

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
                    availableSpace += (Math.floor($(x).css('left')) or 0)
                  if prevSibling.size() > 0
                    availableSpace -= (prevSibling.offset().left - ourLeft + prevSibling.outerWidth())
                  if availableSpace > neededSpace
                    usedSpace = 0
                    prevSiblings.each (i, s) ->
                      oldLeft = Math.floor($(s).css('left')) or 0
                      if availableSpace > 0
                        useWidth = Math.floor(oldLeft * (neededSpace - usedSpace) / availableSpace)
                        $(s).css('left', (oldLeft - useWidth - usedSpace) + "px")
                        usedSpace += useWidth
                        availableSpace -= oldLeft

                    neededSpace = -neededSpace
                  else
                    prevSiblings.each (i, s) -> $(s).css('left', "0px")                      
                    neededSpace = 0
              if neededSpace > 0
                if prevSibling.size() > 0
                  if neededSpace < Math.floor(prevSibling.css('left'))
                    neededSpace = Math.floor(prevSibling.css('left'))
                rendering.$el.css
                    'position': 'relative'
                    'left': (neededSpace) + "px"
                rendering.left = neededSpace / that.getScale()
                rendering.setScale = (s) ->
                  rendering.$el.css
                    'left': Math.floor(rendering.left * s) + "px"


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
          item = model.getItem id
          if item.sgatextAlignment?.length > 0
            lineAlignments[currentLine] = item.sgatextAlignment[0]
          if item.indent?.length > 0
            lineIndents[currentLine] = Math.floor(item.indent[0]) or 0
          currentLine += 1
          null

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

        $(container).css
          'overflow': 'hidden'

        that.onDestroy? that.events.onScaleChange.addListener (s) ->
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
          return unless 'Text' in (options.types || [])

          rendering = {}
          item = model.getItem id

          textContainer = $("<div></div>")

          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y
          
          $(textContainer).css
            "position": "absolute"
            "left": Math.floor(16 + x * that.getScale()) + "px"
            "top": Math.floor(y * that.getScale()) + "px"
            "width": Math.floor(width * that.getScale()) + "px"
            "height": Math.floor(height * that.getScale()) + "px"

          container.append(textContainer)
          overflowDiv = $("<div></div>")
          container.append overflowDiv
          rootEl = $("<div></div>")
          $(rootEl).addClass("text-content")
          $(overflowDiv).css
            'overflow': 'auto'
            'height': Math.floor(height * that.getScale()) + "px"
            'width': Math.floor(width * that.getScale()) + "px"

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
              "left": Math.floor(16 + x * s) + "px"
              "top": Math.floor(y * s) + "px"
              "width": Math.floor(width * s) + "px"
              "height": Math.floor(height * s) + "px"
            $(overflowDiv).css
              'height': Math.floor(height * that.getScale()) + "px"
              'width': Math.floor(width * that.getScale()) + "px"
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
          return unless 'Text' in (options.types || [])
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

          updateMarque = (z) ->

          app = options.application()

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
          marqueeWidth = Math.floor((that.getWidth() * visiblePerc * that.getScale())/100, 10 )
          marqueeHeight = Math.floor((that.getHeight() * visiblePerc * that.getScale())/100, 10 )

          # we do our own clipping because of the way margins and padding play with us

          updateMarque = (z) ->
            if app.imageControls.getMaxZoom() > 0
              

              width  = Math.floor(that.getWidth() * that.getScale() / Math.pow(2, z))
              visiblePerc = Math.min(100, width * 100 / $(container).width())

              marqueeWidth = Math.floor((that.getWidth() * visiblePerc * that.getScale())/100, 10 )
              marqueeHeight = Math.floor((that.getHeight() * visiblePerc * that.getScale())/100, 10 )
              
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

          that.onDestroy? app.imageControls.events.onZoomChange.addListener updateMarque

          that.onDestroy? app.imageControls.events.onImgPositionChange.addListener (p) ->
            marqueeLeft = Math.floor( (-p.topLeft.x * that.getScale()) )
            marqueeTop = Math.floor( (-p.topLeft.y * that.getScale()) )

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

          #if app.imageControls?.getActive()
          #  $('.marquee').show()
          #else
          $('.marquee').hide()

          that.onDestroy? app.imageControls?.events.onActiveChange.addListener (a) ->
            if a
              $('.marquee').show()
            else
              $('.marquee').hide()

          that.events.onScaleChange.addListener (s) ->
            updateMarque(app.imageControls.getZoom())

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
            left: Math.floor(16 + x * that.getScale()) + "px"
            top: Math.floor(y * that.getScale()) + "px"
            width: Math.floor(width * that.getScale()) + "px"
            height: Math.floor(height * that.getScale()) + "px"

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
              left: Math.floor(16 + x * s) + "px"
              top: Math.floor(y * s) + "px"
              width: Math.floor(width * s) + "px"
              height: Math.floor(height * s) + "px"
            text.setScale s

          rendering.update = (item) ->
            x = if item.x?[0]? then item.x[0] else 0
            y = if item.y?[0]? then item.y[0] else 0
            width = if item.width?[0]? then item.width[0] else options.width - x
            height = if item.height?[0]? then item.height[0] else options.height - y
            that.setHeight height
            $(textContainer).css
              left: Math.floor(16 + x * that.getScale()) + "px"
              top: Math.floor(y * that.getScale()) + "px"
              width: Math.floor(width * that.getScale()) + "px"
              height: Math.floor(height * that.getScale()) + "px"
          rendering

        that.addLens 'Image', (innerContainer, view, model, id) ->
          return unless 'Image' in (options.types || [])

          rendering = {}

          item = model.getItem id

          htmlImage = null
          height = 0
          y = 0
          x = 0
          width = 0
          renderImage = (item) ->
            if item.image?[0]?
              x = if item.x?[0]? then item.x[0] else 0
              y = if item.y?[0]? then item.y[0] else 0
              width = if item.width?[0]? then item.width[0] else options.width - x
              height = if item.height?[0]? then item.height[0] else options.height - y
              s = that.getScale()
              if htmlImage?
                htmlImage.remove()
              htmlImage = $("<img></img>")
              $(innerContainer).append(htmlImage)
              htmlImage.attr
                height: Math.floor(height * s)
                width: Math.floor(width * s)
                src: item.image[0]
                border: 'none'
              htmlImage.css
                position: 'absolute'
                top: Math.floor(y * s)
                left: Math.floor(x * s)

          renderImage(item)

          rendering.setScale = (s) ->
            if htmlImage?
              htmlImage.attr
                height: Math.floor(height * s)
                width: Math.floor(width * s)
              htmlImage.css
                top: Math.floor(y * s)
                left: Math.floor(x * s)

          rendering.getHeight = -> height

          rendering.getY = -> y

          rendering.update = renderImage

          rendering.remove = ->
            if htmlImage?
              htmlImage.remove()
              htmlImage = null
          rendering

        # This tile-based image viewer does not use SVG for now to avoid issues with FireFox
        that.addLens 'ImageViewer', (innerContainer, view, model, id) ->
          return unless 'Image' in (options.types || [])

          rendering = {}

          djatokaTileWidth = 256

          item = model.getItem id

          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y

          divWidth = $(container).width() || 1
          divHeight = $(container).height() || 1

          divScale = that.getScale()
          imgScale = divScale

          $(innerContainer).css
            'overflow': 'hidden'
            'position': "absolute"
            'top': 0
            'left': '16px'

          imgContainer = $("<div></div>")
          $(innerContainer).append(imgContainer)

          app.imageControls.setActive(true)

          baseURL = item.url[0]
          tempBaseURL = baseURL.replace(/http:\/\/tiles2\.bodleian\.ox\.ac\.uk:8080\//, 'http://dev.shelleygodwinarchive.org/')

          rendering.update = (item) ->

          zoomLevel = null

          rendering.getZoom = -> zoomLevel
          rendering.setZoom = (z) ->
          rendering.setScale = (s) ->
          rendering.getScale = -> divScale
          rendering.getX = ->
          rendering.setX = (x) ->
          rendering.getY = ->
          rendering.setY = (y) ->

          offsetX = 0
          offsetY = 0

          rendering.setOffsetX = (x) ->
          rendering.setOffsetY = (y) ->
          rendering.getOffsetX = -> offsetX
          rendering.getOffsetY = -> offsetY

          rendering.remove = ->
            $(imgContainer).empty()

          $.ajax
            url: tempBaseURL + "&svc_id=info:lanl-repo/svc/getMetadata"
            success: (metadata) ->
              # original{Width,Height} are the size of the full jp2 image - the maximum resolution            
              originalWidth = Math.floor(metadata.width) || 1
              originalHeight = Math.floor(metadata.height) || 1
              imgScale = width / originalWidth
              # zoomLevels are how many different times we can divide the resolution in half
              zoomLevels = Math.floor(metadata.levels)
              # div{Width,Height} are the size of the HTML <div/> in which we are rendering the image
              divWidth = $(container).width() || 1
              divHeight = $(container).height() || 1
              #divScale = that.getScale()
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
              recalculateBaseZoomLevel = ->
                divWidth = $(container).width() || 1
                if that.getScale?
                  baseZoomLevel = Math.max(0, Math.ceil(-Math.log( that.getScale() * imgScale )/Math.log(2)))
                  app.imageControls.setMinZoom 0
                  app.imageControls.setMaxZoom zoomLevels - baseZoomLevel

              wrapWithImageReplacement = (cb) ->
                cb()
                currentZ = Math.ceil(zoomLevel + baseZoomLevel)
                $(imgContainer).find("img").each (idx, el) ->
                  img = $(el)
                  x = img.data 'x'
                  y = img.data 'y'
                  z = img.data 'z'
                  if z != currentZ
                    img.css
                      "z-index": -10
                  else
                    img.css
                      "z-index": 0

              _setZoom = (z) ->
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
             
              rendering.setZoom = (z) ->
                if z != zoomLevel
                  _setZoom(z)
                  app.imageControls.setZoom(z)

              rendering.setScale = (s) ->
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

              that.onDestroy? app.imageControls.events.onZoomChange.addListener rendering.setZoom

              updateImageControlPosition = ->
                app.imageControls.setImgPosition
                  topLeft: 
                    x: offsetX * imgScale
                    y: offsetY * imgScale


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
                        MITHgrid.mouse.capture (type) ->
                          e = this
                          switch type
                            when "mousemove"
                              if !startX? or !startY?
                                startX = e.pageX
                                startY = e.pageY
                              scoords = screen2original(startX - e.pageX, startY - e.pageY)
                              offsetX = startoffsetX - scoords.left
                              offsetY = startoffsetY - scoords.top
                              renderTiles()
                              updateImageControlPosition()

                            when "mouseup"
                              inDrag = false
                              MITHgrid.mouse.uncapture()

                    imgEl.bind 'mousewheel DOMMouseScroll MozMousePixelScroll', (e) ->
                      e.preventDefault()
                      inDrag = false
                    
                      x = e.originalEvent.offsetX + parseInt($(imgEl).css('left'), 10)
                      y = e.originalEvent.offsetY + parseInt($(imgEl).css('top'), 10)
                    
                      # we want to change centerX/centerY so that scrollPoint is constant after the zoom
                      z = rendering.getZoom()
                      oldOffsetX = offsetX
                      oldOffsetY = offsetY
                      scrollPoint = screen2original(x, y)
                      oldOffsetX -= scrollPoint.left
                      oldOffsetY -= scrollPoint.top
                      if z >= 0 and z <= zoomLevels - baseZoomLevel
                        rendering.setZoom (z + 1) * (1 + e.originalEvent.wheelDeltaY / 500) - 1
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

              renderTiles = ->
                divWidth = $(container).width() || 1
                divHeight = $(container).height() || 1
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

              rendering.setOffsetX = (x) ->
                offsetX = x
                renderTiles()
                updateImageControlPosition()

              rendering.setOffsetY = (y) ->
                offsetY = y
                renderTiles()
                updateImageControlPosition()

              rendering.addoffsetX = (dx) ->
                rendering.setOffsetX offsetX + dx

              rendering.addoffsetY = (dy) ->
                rendering.setOffsetY offsetY + dy

              rendering.setZoom(0)

          rendering
  #
  # ## Presentation.Canvas
  #

  #
  # This is the wrapper around a root presentation that gets things started.
  # It handles things when 'Text' is the only presentation type (@data-types)
  #

  Presentation.namespace "Canvas", (Canvas) ->
    Canvas.initInstance = (args...) ->
      MITHgrid.Presentation.initInstance "SGA.Reader.Presentation.Canvas", args..., (that, container) ->
        # we're just going to be a div with positioned child divs
        options = that.options

        annoExpr = that.dataView.prepare(['!target'])
        container.css
          'overflow': 'hidden'

        viewEl = $("<div></div>")
        container.append(viewEl)
        $(viewEl).height(Math.floor($(container).width() * 4 / 3))
        $(viewEl).css
          'background-color': 'white'
          'z-index': 0

        canvasWidth = null
        canvasHeight = null

        baseFontSize = 150 # in terms of the SVG canvas size - about 15pt
        DivHeight = null
        DivWidth = Math.floor($(container).width()*20/20)
        $(container).height(Math.floor($(container).width() * 4 / 3))

        resizer = ->
          DivWidth = Math.floor($(container).width()*20/20,10)
          if canvasWidth? and canvasWidth > 0
            that.setScale  DivWidth / canvasWidth
          if canvasHeight? and canvasHeight > 0
            $(container).height(DivHeight = Math.floor(canvasHeight * that.getScale()))

        MITHgrid.events.onWindowResize.addListener resizer

        $(viewEl).css
          'border': '1px solid grey'
          'background-color': 'white'

        that.events.onScaleChange.addListener (s) ->
          if canvasWidth? and canvasHeight?
            DivHeight = Math.floor(canvasHeight * s)
          $(viewEl).css
            'font-size': (Math.floor(baseFontSize * s * 10) / 10) + "px"
            'line-height': (Math.floor(baseFontSize * s * 11.5) / 10) + "px"
            'height': DivHeight
            'width': DivWidth
          realCanvas?.setScale s
          $(container).trigger("sizeChange", [{w:$(container).width(), h:$(container).height()}])

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
          realCanvas = SGA.Reader.Presentation.Zone.initInstance viewEl,
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
          realCanvas = SGA.Reader.Presentation.Zone.initInstance viewEl,
            types: options.types
            dataView: dataView
            application: options.application
            height: canvasHeight
            width: canvasWidth
            scale: DivWidth / canvasWidth
          that.setHeight canvasHeight
          realCanvas.events.onHeightChange.addListener that.setHeight
