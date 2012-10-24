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
                if node.type != "br"
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
