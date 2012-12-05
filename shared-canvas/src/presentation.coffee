# # Presentations
SGAReader.namespace "Presentation", (Presentation) ->

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

          rendering.remove = ->
            #if svgImage? and svgRoot?
            #  svgRoot.remove svgImage
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
            key: id

          zone = Zone.initInstance zoneContainer,
            types: options.types
            dataView: zoneDataView
            svgRoot: svgRoot
            application: options.application
            heigth: height
            width: width

          rendering._destroy = ->
            zone._destroy() if zone._destroy?
            zoneDataView._destroy() if zoneDataView._destroy?

          rendering.remove = ->
            #if svgRoot? and container?
            #  $(container).empty()
            #  svgRoot.remove container
            rendering._destroy()
 
          rendering

        that.addLens 'TextContent', (container, view, model, id) ->
          return unless 'Text' in (options.types || [])

          console.log "TextContent:", id
          rendering = {}
          app = options.application()
          item = model.getItem id
 
          textContainer = null
          textContainer = document.createElementNS('http://www.w3.org/2000/svg', 'foreignObject' )
          # pull start/end/width/height from constraint with a default of
          # the full surface
          x = if item.x?[0]? then item.x[0] else 0
          y = if item.y?[0]? then item.y[0] else 0
          width = if item.width?[0]? then item.width[0] else options.width - x
          height = if item.height?[0]? then item.height[0] else options.height - y
          console.log item
          console.log "Setting up text container", x, y, width, height
          $(textContainer).attr("x", x).attr("y", y).attr("width", width).attr("height", height)
          container.appendChild(textContainer)

          rendering.remove = ->
            #$(textContainer).empty()
            #svgRoot.remove textContainer

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
              css: info.css.join(" ")
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
              css: [ ]

            results = []
            br_pushed = false

            for pos in [ 0 ... text.length ]
              if !mods[pos+offset]?
                br_pushed = false unless text[pos].match(/^\s+$/)
                current_el.acc += text[pos]
              else
                results.push processNode(current_el)

                current_el.acc = text[pos]
                for mod in mods[pos+offset]
                  if mod.type == "LineAnnotation"
                    if !br_pushed
                      results.push { type: 'br', modes: [], acc: '', css: '' }
                      br_pushed = true
                  if mod.action == 'start'
                    current_el.modes.push mod.type
                    current_el.css.push mod.css
                  if mod.action == 'end'
                    current_el.modes = (i for i in current_el.modes when i != mod.type)   

            results.push processNode(current_el)
            results

          text = ""
          mods = {}

          setMod = (pos, pref, type, css) ->
            pos = pos[0] if $.isArray(pos)
            mods[pos] = [] unless mods[pos]?
            type = type[0] if $.isArray(type)
            mods[pos].push
              action: pref
              type: type
              css: css

          app.withSource item.source?[0], (content) ->
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
                setMod hitem.start, 'start', hitem.type, hitem.css
                setMod hitem.end, 'end', hitem.type, ''

            nodes = compileText
              text: text
              mods: mods
              offset: item.start[0]

            tags = {}
            bodyEl = document.createElementNS('http://www.w3.org/1999/xhtml', 'body')   
            rootEl = document.createElement('div')
            $(rootEl).addClass("text-content")
            $(rootEl).css("font-size", 150)
            $(rootEl).css("line-height", 1.15)
            bodyEl.appendChild(rootEl)

            #numberOfLines = 0
            for node in nodes
              el = $("<#{node.type} />")
              if node.type == "br"
                $(rootEl).append($("<span class='linebreak'></span>"))
                #numberOfLines += 1
              else
                el.text(node.text)
              el.addClass(node.classes)
              el.attr("css", node.css)
              $(rootEl).append(el)
              for mode in node.modes
                tags[mode] ?= []
                tags[mode].push el
            #if numberOfLines > 24
            #  # make the font height fit into the page
            #  $(rootEl).css("font-size", parseInt(30*100 / numberOfLines, 10) + "%");   
            textContainer.appendChild(bodyEl)

          rendering.update = (item) ->
            # do nothing for now
          rendering

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
        SVGWidth = parseInt($(container).width()*19/20, 10)
        MITHGrid.events.onWindowResize.addListener ->
          SVGWidth = parseInt($(container).width() * 19/20, 10)
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

              #console.log svgRoot
              #svgRootEl.scale(s)
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
