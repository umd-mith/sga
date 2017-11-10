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

      manifestUrl = config.manifest
      searchService = config.searchService

      # Instantiate manifests collection and view
      manifests = SGASharedCanvas.Data.Manifests
      new ManifestsView
        collection : manifests
        searchService : searchService
      # Add manifest from DOM. This triggers data collection and rendering.
      manifest = manifests.add
        url: manifestUrl
      if manifestUrl == "#local"
        manifest.parse window.manifest
        manifest.sync()
      else
        manifest.fetch()

      # Activate Routers
      Backbone.history.start()

  # Manifests view
  class ManifestsView extends Backbone.View

    initialize: (options) ->
      @searchService = options.searchService
      @listenTo @collection, 'add', @addOne

    addOne: (model) ->
      new ManifestView
        model: model
        searchService: @searchService

    render: ->
      @

  # Manifest view
  class ManifestView extends Backbone.View

    # Instead of generating a new element, bind to the existing skeleton
    # already present in the HTML.
    el: '#SGASharedCanvasViewer'

    initialize: (options) ->

      fetchCanvas = (n) =>
        # For now we assume there is only one sequence.
        # Eventually this should be on a sequence view.
        # From the sequence, we locate the correct canvas id
        sequence = @model.sequences.first()

        canvases = sequence.get "canvases"

        # filter out undefined canvases
        canvases = _.filter canvases, (c) ->
          return c != undefined

        @variables.set "seqMax", canvases.length
        @variables.set "seqPage", parseInt(n)

        n = canvases.length if n > canvases.length
        canvasId = canvases[n-1]
        # Create the view
        canvas = @model.canvasesData.add
          id : canvasId
        # Finally fetch the data. This will cause the views to render.
        canvas.fetch @model

        # Render canvas metadata
        new CanvasMetaView
          el: "#SGACanvasMeta"
          model: @model.canvasesMeta.get canvasId

      @model.ready = (cb) ->
        if @sequences.length > 0
          cb()
        else
          @once "sync", cb

      # Set view properties
      @variables = new SGASharedCanvas.Utils.AudibleProperties
        seqPage: 0
        seqMin: 1
        seqMax: 0

      # Set templates
      @metaTemplate = _.template($('#manifestMeta-tpl').html())
      @citationTemplate = _.template($('#citation-tpl').html())

      # Add views for child collections right away
      @canvasesView = new CanvasesView collection: @model.canvasesData

      # When a new canvas is requested through a Router, fetch the right canvas data.
      @listenTo SGASharedCanvas.Data.Manifests, 'page', (n, paras) ->
        # First of all, destroy any canvas already loaded. We do this for two reasons:
        # 1. it avoids piling up canvases data in the browser memory
        # 2. it causes previously instantiated views to destroy themselves and make room for the new one.
        @model.canvasesData.reset()
        # Also clear search results, if any.
        @model.searchResults.reset()
        Backbone.trigger "viewer:searchResults", []

        if paras?
          if paras.mode?

            filter = []

            switch paras.mode
              when "img" then filter.push "Image"
              when "std", "rdg", "xml" then filter.push "Image", "Text"
              when "txt" then filter.push "Text"

            @canvasesView.filter = filter

            @model.ready =>
              fetchCanvas n

              if paras.mode == "rdg"

                curCanvas = @model.canvasesData.first()

                layerAnnos = curCanvas.layerAnnos.find (m) ->
                  return m.get("sc:motivatedBy")["@id"] == "sga:reading"

                # Make full URL to XML relative
                html_url = layerAnnos.get("resource")
                # offline mode
                if window.mapping
                  d = $.parseHTML window.mapping[html_url]
                  for e in d
                    if $(e).is('div')
                      $(e).addClass("readingText")
                      curCanvas.trigger "addLayer", "Text", e
                else
                  html_url = html_url.replace(/^http:\/\/.*?(:\d+)?\//, "/")

                  $.get html_url, ( data ) ->
                    d = $.parseHTML data
                    for e in d
                      if $(e).is('div')
                        $(e).addClass("readingText")
                        curCanvas.trigger "addLayer", "Text", e

              else if paras.mode == "xml"

                curCanvas = @model.canvasesData.first()

                layerAnnos = curCanvas.layerAnnos.find (m) ->
                  return m.get("sc:motivatedBy")["@id"] == "sga:source"

                # Make full URL to XML relative
                xml_url = layerAnnos.get("resource")
                if window.mapping
                  txtdata = window.mapping[xml_url]
                  txtdata = txtdata.replace /\&/g, '&amp;'
                  txtdata = txtdata.replace /%/g, '&#37;'
                  txtdata = txtdata.replace /</g, '&lt;'
                  txtdata = txtdata.replace />/g, '&gt;'
                  xml = "<pre class='prettyprint'><code class='language-xml'>"+txtdata+"</code></pre>"
                  curCanvas.trigger "addLayer", "Text", xml
                  prettyPrint()
                else
                  xml_url = xml_url.replace(/^http:\/\/.*?(:\d+)?\//, "/")
                  callback = ( data ) ->
                    surface = data.getElementsByTagName 'surface'
                    serializer = new XMLSerializer()
                    txtdata = serializer.serializeToString surface[0]
                    txtdata = txtdata.replace /\&/g, '&amp;'
                    txtdata = txtdata.replace /%/g, '&#37;'
                    txtdata = txtdata.replace /</g, '&lt;'
                    txtdata = txtdata.replace />/g, '&gt;'

                    xml = "<pre class='prettyprint'><code class='language-xml'>"+txtdata+"</code></pre>"
                    curCanvas.trigger "addLayer", "Text", xml
                    prettyPrint()
                  $.get xml_url, callback, 'xml'

          # When search results are requested through a Router, fetch the search data.
          if paras.query?
            @model.searchResults.fetch @model, paras.filters, paras.query, options.searchService

            @listenToOnce @model.searchResults, 'sync', ->
              searchResultsPositions = []

              @model.ready =>
                canvases = @model.sequences.first().get "canvases"

                @model.searchResults.forEach (res, i) ->
                  trg = res.get("canvas_id")
                  if trg in canvases
                    searchResultsPositions.push($.inArray(trg, canvases)+1)

                fetchCanvas n
                Backbone.trigger "viewer:searchResults", searchResultsPositions
        else
          # Make sure manifest is loaded
          @model.ready =>
            fetchCanvas n

      @render()
      @model.ready @renderMeta

    renderMeta: =>
      # Render Manifest Metadata
      noColon = {}
      for k,v of @model.toJSON()
        escaped = k.replace('http://www.tei-c.org/ns/1.0/idno', 'teiID')
        escaped = escaped.replace(':', '')
        noColon[escaped] = v
      $('#SGAManifestMeta').html @metaTemplate(noColon)

      citation = {}

      if noColon["scagentLabel"]?
        authorParts = noColon["scagentLabel"].split(" ")
        last = authorParts[authorParts.length-1]
        initials = ""
        for parts in authorParts[...-1]
          initials += parts.substring(0,1) + ". "
        citation["author"] = last + ", " + initials

      if noColon["scdateLabel"]?
        dateParts = noColon["scdateLabel"].split(" ")
        citation["year"] = dateParts[dateParts.length-1]

      if noColon["dctitle"]?
        citation["title"] = if noColon["label"]? then noColon["label"] else ""

      $('#cite-manifest').html @citationTemplate(citation)

    render: ->
      # Manage UI components as subviews
      syncVarsFor = (component) =>

        component.listenTo @variables, 'change', (p) ->
          for k,v of @variables.variables
            component.variables.set k, p[k]

      # Pager
      pager = new SGASharedCanvas.Component.Pager
        el : '#sequence-nav'
        vars: @variables.variables

      syncVarsFor pager

      # Slider
      slider = new SGASharedCanvas.Component.Slider
        el : '#page-location'
        vars: @variables.variables
        data: @model

      syncVarsFor slider

      # Reading Mode Controls
      readingModeControls = new SGASharedCanvas.Component.ReadingModeControls
        el : '#mode-controls'
        vars: @variables.variables

      syncVarsFor readingModeControls

      # Limit View Controls
      limitViewControls = new SGASharedCanvas.Component.LimitViewControls
        el : '#limit-view-controls'
        include: ['hand-library', 'hand-comp']
        defLimiter: 'hand-mws'

      # Spinner (temp)
      $('#loading-progress').css
        position: "absolute"
        "z-index": "10000"
        top: "50%"
        left: "50%"

      # Search Box
      searchBox = new SGASharedCanvas.Component.SearchBox
        el: "#sgaForm"

      @

  # Canvases view
  class CanvasesView extends Backbone.View

    initialize: ->
      @listenTo @collection, 'add', @addOne

    addOne: (c) ->
      # Only trigger views once the model contains canvas data (but not subcollections yet)
      $('#loading-progress').show()
      @listenToOnce c, 'sync', =>
        $('#loading-progress').hide()
        new CanvasView
          model: c
          filter: @filter

    render: ->
      @

  # Canvas view
  class CanvasView extends Backbone.View

    initialize: (options) ->
      @listenTo @model, 'remove', @remove

      @render(options["filter"])

    render: (filter) ->
      # Here we collect data-types expressed in HTML and
      # we organize further collections according to them.

      # filter is used to specify which areas to render (default: all)

      areas = []

      tpl = $($('#canvas-tpl').html())

      tpl.find('.sharedcanvas').each ->
        data = $(@).data()
        data["el"] = @
        if filter?
          if data.types in filter
            areas.push data
        else
          areas.push data

      # Attach the template to #mainSharedCanvas (must be provided in the HTML)
      # Eventually we could take the destination div as a paramenter when initializing the app.
      @$el.append tpl
      $("#mainSharedCanvas").append @$el

      for area in areas
        # First, determine how many Bootstrap columns each area takes
        col = parseInt(12 / areas.length)
        $(area.el).addClass("col-xs-"+col)

        # We use canvas data to render views for the areas.
        # Each area is an independent view on the canvas data.
        new ViewerAreaView
          model: @model
          el: area.el
          types: area.types.split(" ")
      @

  # Canvas Meta view
  class CanvasMetaView extends Backbone.View

    initialize: ->
      @template = _.template($('#canvasMeta-tpl').html())
      @citationTemplate = _.template($('#citation_canvas-tpl').html())
      @render()

    render: ->
      noColon = {}
      for k,v of @model.toJSON()
        noColon[k.replace(':', '')] = v
      # Handle status metadata (at the moment not in manifest)
      noColon.trans = "green"
      noColon.meta = "green"

      @$el.html @template(noColon)

      citation =
        "url" : document.URL

      if noColon["sgashelfmarkLabel"]? and noColon["sgafolioLabel"]?
        citation["page"] = noColon["sgashelfmarkLabel"] + ", " + noColon["sgafolioLabel"]

      $('#cite-canvas').html @citationTemplate(citation)


  # General area view, declaring variables that can be tracked with events
  class AreaView extends Backbone.View
    initialize: (options) ->
      # Set view properties
      @variables = new SGASharedCanvas.Utils.AudibleProperties
        height: 0
        width : 0
        x     : 0
        y     : 0
        scale : 0
        scrollWidth: 0

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

      # Deal with layers
      @listenTo @model, 'addLayer', (area, content) ->
        if area in @types
          @addLayer(content)

      @render()

    render: ->
      @$el.css 'overflow': 'hidden'

      container = $("<div></div>")
      @$el.append(container)

      gcd = (x, y) ->
        [x, y] = [y, x%y] until y is 0
        x

      canvasWidth = @model.get("width")
      canvasHeight = @model.get("height")

      aspectRatio = gcd canvasWidth, canvasHeight

      $(container).height(Math.floor(@$el.width() * (canvasWidth / aspectRatio) / (canvasHeight / aspectRatio)))
      $(container).css
        'background-color': 'white'
        'z-index': 0

      baseFontSize = 110 # in terms of the image size - about 15pt
      DivHeight = null
      DivWidth = Math.floor(@$el.width()*20/20)
      @$el.height(Math.floor(@$el.width() * (canvasWidth / aspectRatio) / (canvasHeight / aspectRatio)))

      # This figures out the scale for our further calculations.
      resizer = =>
        aspectRatio = gcd canvasWidth, canvasHeight
        DivWidth = Math.floor(@$el.width()*20/20,10)
        if canvasWidth? and canvasWidth > 0
          @variables.set 'scale', DivWidth / canvasWidth
        if canvasHeight? and canvasHeight > 0
          @$el.height(DivHeight = Math.floor(canvasHeight * @variables.get 'scale'))
        # Propagate to the rest of the viewer
        Backbone.trigger "viewer:resize", {container: @$el, scale: @variables.get('scale')}

      $(window).on "resize", resizer

      container.css
        'border': '1px solid grey'
        'background-color': 'white'

      @listenTo @variables, 'change:scale', (s) ->
        if canvasWidth? and canvasHeight?
          DivHeight = Math.floor(canvasHeight * s)
        container.css
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
        container.append new ImagesView(
          collection: @model.images
          el: container
          vars: @variables.variables # Pass on variables set in this view
        ).render().el

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

    addLayer: (content) ->
      @$el.children().html(content)
      @$el.children().css("overflow", "auto")

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

      @$el.css
        left: Math.floor(16 + x * @variables.get('scale')) + "px"
        top: Math.floor(y * @variables.get('scale')) + "px"
        width: Math.floor(width * @variables.get('scale')) + "px"
        height: Math.floor(height * @variables.get('scale')) + "px"

      setScale = (s) =>
        @$el.css
          left: Math.floor(16 + x * s) + "px"
          top: Math.floor(y * s) + "px"
          width: Math.floor(width * s) + "px"
          height: Math.floor(height * s) + "px"
        if @$el.perfectScrollbar?
          @$el.perfectScrollbar('update')
      Backbone.on 'viewer:resize', (options) =>
        setScale options.scale

      # Style scrollbars if plugin is present

      if @$el.perfectScrollbar?
        @$el.css
          overflow: 'hidden'
        @$el.perfectScrollbar
          suppressScrollX: true
          includePadding: true
          scrollYMarginOffset: 10

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

      @currentLine = 0

      @currentLineEl = $("<div></div>")
      @$el.append @currentLineEl

      @lastRendering = null
      # Keet track of the last rendering with non-space text
      @lastRenderingNonEmpty = null

      @variables.on 'change:width', (w) =>
        @$el.attr('width', w/10)

      adjustFontSize = =>
        # fix font size
        fs = parseInt(@$el.css('font-size'))
        newfs = fs-1
        @$el.css('font-size', newfs + 'px')
        @variables.set 'fontSize', (fs-1) / @variables.get "scale"

        # Reset line height to 1.5 (font size * 1.5)
        adj = newfs * 2.0
        @$el.css('line-height', adj + 'px')

      @variables.on 'change:scrollWidth', (sw) =>
        if @$el.innerWidth() != 0
          adjustFontSize() while @$el.innerWidth() < @el.scrollWidth

      Backbone.on 'viewer:resize', (options) =>
        if @variables.get('fontSize')?
          @$el.css 'font-size', @variables.get('fontSize') * options.scale

    addOne: (model) ->

      setPosition = (textAnnoView, annoEl) =>
        # Calculate space needed
        # This function may be buggy, would benefit from a better algorithm and tests
        ourWidth = @variables.get("width") / 10
        ourLeft = annoEl.offset().left
        rendering_width = annoEl.width() / @variables.get("scale")
        annoEl.css
          width: Math.ceil(rendering_width * @variables.get("scale")) + "px"

        if @lastRenderingNonEmpty?.get(0)?

          myOffset = annoEl.offset()
          if (@lastRenderingNonEmpty.data("place")? and annoEl.data("place")?) and @lastRenderingNonEmpty.data("place") == "above" and annoEl.data("place") == "below"
              # Although sublinear insertions may influence the position of superlinear insertions,
              # the opposite should not be true.
              middle = myOffset.left + annoEl.outerWidth(false)/2
          else if @lastRenderingNonEmpty.hasClass 'sgaDeletionAnnotation'
            # If the previous is a deletion, stick it in the middle!
            middle = @lastRenderingNonEmpty.offset().left + (@lastRenderingNonEmpty.outerWidth(false)/2)
          else if @lastRenderingNonEmpty.data("line")? and @lastRenderingNonEmpty.data("line") < @currentLine
            # If the last rendered item is in the previous line, set middle to offset left
            middle = myOffset.left
          else
            middle = @lastRenderingNonEmpty.offset().left + (@lastRenderingNonEmpty.outerWidth(false))
          myMiddle = myOffset.left + annoEl.outerWidth(false)/2
          neededSpace = middle - myMiddle

          # now we need to make sure we aren't overlapping with other text - if so, move to the right
          prevSibling = annoEl.prev()
          accOffset = 0
          spacing = 0
          if prevSibling? and prevSibling.size() > 0
            prevOffset = prevSibling.offset()
            accOffset = prevSibling.offset().left + prevSibling.outerWidth(false) - ourLeft
            spacing = (prevOffset.left + prevSibling.outerWidth(false)) - myOffset.left
            spacing = parseInt(prevSibling.css('left'),10) or 0 #(prevOffset.left) - myOffset.left

            if spacing > neededSpace
              neededSpace = spacing

          if neededSpace >= 0
            if neededSpace + (myOffset.left - ourLeft) + accOffset + annoEl.outerWidth(false) > ourWidth

              neededSpace = ourWidth - (myOffset.left - ourLeft) - accOffset - annoEl.outerWidth(false)

          # if we need negative space, then we need to move to the left if we can
          if neededSpace < 0
            # we need to move some of the other elements on this line
            if !prevSibling? or prevSibling.size() <= 0
              neededSpace = 0
            else
              neededSpace = -neededSpace
              prevSiblings = annoEl.prevAll()
              availableSpace = 0
              prevSiblings.each (i, x) ->
                availableSpace += (parseInt($(x).css('left'),10) or 0)
              if prevSibling.size() > 0
                availableSpace -= (prevSibling.offset().left - ourLeft + prevSibling.outerWidth(false))
              if availableSpace > neededSpace
                usedSpace = 0
                prevSiblings.each (i, s) ->
                  oldLeft = parseInt($(s).css('left'), 10) or 0
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
              if neededSpace < parseInt(prevSibling.css('left'), 10)
                neededSpace = parseInt(prevSibling.css('left'), 10)
            annoEl.css
                'position': 'relative'
                'left': (neededSpace) + "px"
          textAnnoView.variables.set "left", neededSpace / @variables.get("scale")
          textAnnoView.variables.set "width", annoEl.width() / @variables.get("scale")
          setScale = (s) =>
            annoEl.css
              'left': Math.floor(textAnnoView.variables.get("left") * s) + "px"
              'width': Math.ceil(textAnnoView.variables.get("width") * s) + "px"
          Backbone.on 'viewer:resize', (options) =>
            setScale options.scale

      # Instantiate different views depending on the type of annotation.
      type = model.get "type"
      _getTextWidth = (container) ->
            container = $(container)

            o = container.clone()
                  .css(
                    'position': 'absolute'
                    'float': 'left'
                    'white-space': 'nowrap'
                    'visibility': 'hidden'
                  )
                  .appendTo($('body'))
            text = $.trim(o.text().replace(/\s+/g,' '))
            o.text(text)
            w_px = o.width()
            font_size = o.css('font-size')
            font_size = parseInt(font_size.substring(0, font_size.length - 2))
            o.remove()
            w_px / font_size
      switch
        when "sgaAdditionAnnotation" in type

          # Parse additions first, as they might require an extra line
          if /vertical-align: super;/.test(model.get("css"))
            additionLine = if not @currentLineEl.prev().hasClass('above-line') \
                           then $("<div class='above-line'></div>")\
                           else @currentLineEl.prev()

            textAnnoView = new TextAnnoView
              model: model
            annoEl = $ textAnnoView.render()?.el
            annoEl.data "place", "above"
            annoEl.data "line", @currentLine
            additionLine.append(annoEl).insertBefore(@currentLineEl)

            if annoEl.get(0)?
              setPosition(textAnnoView, annoEl)
              @lastRendering = annoEl
              if textAnnoView.model.attributes.text.replace(/\s+/, '') != ''
                @lastRenderingNonEmpty = annoEl

          else if /vertical-align: sub;/.test(model.get("css"))
            additionLine = null
            if not @currentLineEl.next().hasClass('below-line')
              additionLine = $("<div class='below-line'></div>")
              indent = @currentLineEl.data('indent')
              if indent?
                additionLine.css
                  'padding-left' : indent
            else
              additionLine = @currentLineEl.next()

            textAnnoView = new TextAnnoView
              model: model
            annoEl = $ textAnnoView.render()?.el
            annoEl.data "place", "below"
            annoEl.data "line", @currentLine
            additionLine.append(annoEl).insertAfter(@currentLineEl)

            if annoEl.get(0)?
              setPosition(textAnnoView, annoEl)
              @lastRendering = annoEl
              if textAnnoView.model.attributes.text.replace(/\s+/, '') != ''
                @lastRenderingNonEmpty = annoEl

          else
            textAnnoView = new TextAnnoView
              model: model
            annoEl = $ textAnnoView.render()?.el
            annoEl.data "line", @currentLine
            @lastRendering = annoEl
            if textAnnoView.model.attributes.text.replace(/\s+/, '') != ''
                @lastRenderingNonEmpty = annoEl
            @currentLineEl.append annoEl

        when "Text" in type \
        or "sgaLineAnnotation" in type \
        or "sgaDeletionAnnotation" in type \
        or "sgaSearchAnnotation" in type
          textAnnoView = new TextAnnoView
            model: model
          annoEl = $ textAnnoView.render()?.el
          annoEl.data "line", @currentLine
          @currentLineEl.append annoEl
          if annoEl.get(0)?
            @lastRendering = annoEl
            if textAnnoView.model.attributes.text.replace(/\s+/, '') != ''
                @lastRenderingNonEmpty = annoEl
        when 'EmptyLine' in type
          ext = parseInt(model.get('ext'))
          for br in [1..ext+1]
            # Find the first line that is not an above insertion
            l = @currentLineEl.prev('div:not(.above-line)')
            if l.get(0)?
              l.append("<br/>")
            else
              @$el.prepend("<br/>")
          @$el.append @currentLineEl
        when "LineBreak" in type

          # Before creating a new line container, add other classes on the current one.
          # For example, alignment and indentation are stored on the line break annotation
          # and must be processed now.

          # store padding info to pass it on
          padding = 0

          prev1 = @currentLineEl.prev()
          next1 = @currentLineEl.next()

          if model.get("align")?
            @currentLineEl.data
              'align' : model.get("align")

            # Add alignment to interlinear additions, if present
            if next1.hasClass('below-line')
              next1.data
                  'align_addition': 'with_above'
            if prev1.hasClass('above-line')
              prev1.data
                  'align_addition': 'with_below'

          if model.get("indent")?
            @currentLineEl.data
                 'indent': model.get("indent")

            # Add indentation to interlinear additions, if present
            if next1.hasClass('below-line')
              next1.data
                  'align_addition': 'with_above'
            if prev1.hasClass('above-line')
              prev1.data
                  'align_addition': 'with_below'

          # Only now overwrite the @currentLineEl variable
          # and add a new line container that will be populated at the next run of addOne()
          @currentLineEl = $("<div></div>").data
            "indent" : padding
          @$el.append @currentLineEl

          # Update currentLine count
          @currentLine += 1

      if @variables.get('scrollWidth') != @el.scrollWidth
        @variables.set('scrollWidth', @el.scrollWidth)

      # Adjust indentation and alignment to width of longest line so far.
      lines = @$el.find('.sgaLineAnnotation')
      arr = lines.map(->
          return $(this).text().length
      ).get()
      longest_line = lines[arr.indexOf(Math.max.apply(Math,arr))]

      if longest_line?
        w = _getTextWidth(longest_line)
        a = @$el.find('div').filter(->
          return $(this).data('indent') or $(this).data('align')
        ).each(->
          l = $(this)
          al = l.data('align')
          ind = l.data('indent')
          if al?
            curTextLength = _getTextWidth(l)
            if al == "right"
              if lines.length == 1
                l.css
                  'text-align' : 'right',
                  'padding-right' : '4em',
              else
                l.css
                  'text-align' : 'left',
                  'padding-right' : '0em'
              padding = (w - curTextLength) + "em"
            else if al == "center"
              padding = ((w / 2) - (curTextLength/2)) + "em"
            l.css
              'padding-left': padding
          else if ind?
            l.css
              'padding-left': (w * ind) / 10 + "em"
        )
        # Now align additions with their main line
        a = @$el.find('div').filter(->
          return $(this).data('align_addition')
        ).each(->
          l = $(this)
          where = l.data('align_addition')
          if where == 'with_below'
            padding = l.next().css('padding-left')
            l.css
              'padding-left': padding
          else
            padding = l.prev().css('padding-left')
            l.css
              'padding-left': padding
        )


      # Update scrollbar styling if plugin exists
      if @$el.parent().perfectScrollbar?
        @$el.parent().perfectScrollbar('update')

  class TextAnnoView extends AreaView
    tagName: "span"

    render: ->
      @$el.css
        'display': 'inline'
      @$el.text @model.get "text"
      @$el.addClass @model.get("type").join(" ")

      icss = @model.get "css"
      if icss? and not /^\s*$/.test(icss)
        cur_style = @$el.attr("style")
        @$el.attr("style", cur_style + " " + icss)

      content = @model.get("text").replace(/\s+/g, " ")
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
        new ImageDjatokaView(
          el: @$el
          model: model
          vars: @variables
        ).render()
      else
        @$el.append new ImageView(
          model: model
          vars: @variables
        ).render().el
        # Set the image container to relative to properly float img elements within.
        @$el.css
          position: 'relative'

    render: ->
      @


  class ImageView extends AreaView

    tagName: 'img'

    render: ->

      x = if @model.get("x")? then @model.get("x") else @variables.get("x")
      y = if @model.get("y")? then @model.get("y") else @variables.get("y")
      width = if @model.get("width")? then @model.get("width") else @variables.get("width") - x
      height = if @model.get("height")? then @model.get("height") else @variables.get("height") - x
      s = @variables.get("scale")

      @$el.attr
        height: Math.floor(height * s)
        width: Math.floor(width * s)
        src: @model.get("@id")
        border: 'none'
      @$el.css
        position: 'absolute'
        top: Math.floor(y * s)
        left: Math.floor(x * s)

      setScale = (s) =>
        @$el.attr
          height: Math.floor(height * s)
          width: Math.floor(width * s)
        @$el.css
          top: Math.floor(y * s)
          left: Math.floor(x * s)
      Backbone.on 'viewer:resize', (options) =>
        setScale options.scale
      @


  class ImageDjatokaView extends AreaView

    initialize: (options) ->
      super

      #
      # Manage UI components as subviews
      #
      syncVarsFor = (component) =>

        component.listenTo @variables, 'change', (p) ->
          for k,v of @variables.variables
            component.variables.set k, p[k]

      # Image Controls
      imageControls = new SGASharedCanvas.Component.ImageControls
        el : '#img-controls'

      @listenTo imageControls.variables, 'change:zoom', (z) ->
        if @dragon?
          switch z
            when 0 then @dragon.viewport.goHome()
            when 1 then @zoomIn()
            when -1 then @zoomOut()
            else @dragon.viewport.goHome()

      @listenTo imageControls.variables, 'change:rotation', (r) ->
        if @dragon?
          switch r
            when 1 then @rotateRight()
            when -1 then @rotateLeft()
            else @dragon.viewport.goHome()

    zoomIn: ->
      if @dragon?
        max = @dragon.viewport.getMaxZoom()
        z = @dragon.viewport.getZoom()

        if max > z
          @dragon.viewport.zoomTo z+1

    zoomOut: ->
      if @dragon?
        min = @dragon.viewport.getMinZoom()
        z = @dragon.viewport.getZoom()

        if min < z
          @dragon.viewport.zoomTo z-1

    rotateRight: ->
      if @dragon?
        r = @dragon.viewport.getRotation()

        newr = r + 90
        if newr > 360
          @dragon.viewport.setRotation 0
        else
          @dragon.viewport.setRotation newr

    rotateLeft: ->
      if @dragon?
        r = @dragon.viewport.getRotation()

        newr = r - 90
        @dragon.viewport.setRotation newr
        if newr < -360
          @dragon.viewport.setRotation 0
        else
          @dragon.viewport.setRotation newr

    render: ->
      if OpenSeadragon? and OpenSeadragon.IIIFTileSource?
        width = if @model.get('width')? then @model.get('width')
        height = if @model.get('height')? then @model.get('height')
        divScale = @variables.get("scale")

        innerContainer = $("<div id='osd-container'></div>")
        innerContainer.css
          "width": width * divScale
          "height": height * divScale

        @$el.html(innerContainer)

        service = @model.get("service")
        static_fallback_service = "https://s3.amazonaws.com/sga-tiles/"

        id = @model.get("@id")
        img = id.replace(/^.*?\/([^\/]+.jp2)$/, "$1")

        full_url = service + img
        static_fallback_full_url = static_fallback_service + id.replace(/^.*images\/(.*?)\.jp2/, "$1")
        # ex: http://192.168.1.219/ox/ms_abinger_c56/ms_abinger_c56-0001

        scaleFactors = [ 1, 2, 4, 8, 16]
        # Offline mode (embedded)
        if window.mapping
          @dragon = OpenSeadragon
            id: 'osd-container'
            tileSources:
              type: 'image'
              url: window.mapping[id]
              crossOriginPolicy: 'Anonymous'
            animationTime: 0
            minZoomLevel: 1
            defaultZoomLevel: 1
            showNavigationControl: false
        # Offline mode (local)
        else if full_url.startsWith('./')
          @dragon = OpenSeadragon
            id: 'osd-container'
            tileSources:
              type: 'image'
              url: full_url
              crossOriginPolicy: 'Anonymous'
            animationTime: 0
            minZoomLevel: 1
            defaultZoomLevel: 1
            showNavigationControl: false
        else
          # Check that URL is reacheable, otherwise fall back to our static tiles.
          if !SGASharedCanvas.imageTrouble
            $.ajax
              url: full_url,
              type:     'GET',
              complete: (xhr) ->
                if xhr.status == 200
                  scaleFactors.push 32
                  if img.includes('ms_abinger_c')
                    service += "frankenstein/"
                  else
                    service += "other/"
                else
                  SGASharedCanvas.imageTrouble = true
                  full_url = static_fallback_full_url

                settings =
                  "@context": "http://iiif.io/api/image/2/context.json",
                  "@id": full_url,
                  "height": height,
                  "width": width,
                  "profile": "http://iiif.io/api/image/2/level1.json",
                  "protocol": "http://iiif.io/api/image",
                  "tiles": [
                    "scaleFactors": scaleFactors,
                    "width": 256
                  ]

                # create the OpenSeadragon Viewer with the TileSource
                @dragon = OpenSeadragon
                  id: 'osd-container'
                  minZoomLevel:       1
                  defaultZoomLevel:   1
                  tileSources: [settings]
                  animationTime: 0
                  showNavigationControl: false

          else
            settings =
              "@context": "http://iiif.io/api/image/2/context.json",
              "@id": static_fallback_full_url,
              "height": height,
              "width": width,
              "profile": "http://iiif.io/api/image/2/level1.json",
              "protocol": "http://iiif.io/api/image",
              "tiles": [
                "scaleFactors": scaleFactors,
                "width": 256
              ]

            # create the OpenSeadragon Viewer with the TileSource
            @dragon = OpenSeadragon
              id: 'osd-container'
              minZoomLevel:       1
              defaultZoomLevel:   1
              tileSources: [settings]
              animationTime: 0
              showNavigationControl: false

      else
        throw new Error "Could not load OpenSeadragon to render JP2 image."

)()
