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
      # manifest = SGASharedCanvas.Data.importFullJSONLD manifestUrl 

      # Instantiate manifests collection and view
      manifests = SGASharedCanvas.Data.Manifests
      new ManifestsView 
        collection : manifests
        searchService : searchService
      # Add manifest from DOM. This triggers data collection and rendering.
      manifest = manifests.add
        url: manifestUrl
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
      @listenTo SGASharedCanvas.Data.Manifests, 'page', (n, search) ->
        # First of all, destroy any canvas already loaded. We do this for two reasons:
        # 1. it avoids piling up canvases data in the browser memory
        # 2. it causes previously instantiated views to destroy themselves and make room for the new one.
        @model.canvasesData.reset()
        # Also clear search results, if any.
        @model.searchResults.reset()
        Backbone.trigger "viewer:searchResults", [] 

      # When search results are requested through a Router, fetch the search data.
        if search?          
          @model.searchResults.fetch @model, search.filters, search.query, options.searchService

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
          @model.ready -> 
            fetchCanvas n

      # Deal with reading modes
      @listenTo SGASharedCanvas.Data.Manifests, 'readingMode', (m) ->

        @model.canvasesData.reset()

        filter = []

        switch m
          when "img" then filter.push "Image"
          when "std" then filter.push "Image", "Text"
          when "txt" then filter.push "Text"

        @canvasesView.filter = filter

        fetchCanvas @variables.get "seqPage"

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
        for parts in authorParts
          initials += parts.substring(0,1) + ". "
        citation["author"] = last + ", " + initials

      if noColon["scdateLabel"]?
        dateParts = noColon["scdateLabel"].split(" ")
        citation["year"] = dateParts[dateParts.length-1]

      if noColon["dctitle"]?
        notebook = if noColon["label"]? then noColon["label"] else ""
        citation["title"] = noColon["dctitle"] + " - " + notebook

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

      # Limit View Controls
      limitViewControls = new SGASharedCanvas.Component.LimitViewControls
        el : '#hand-view-controls'
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

      @variables.on 'change:width', (w) =>
        @$el.attr('width', w/10)

      adjustFontSize = =>
        # fix font size
        fs = parseInt(@$el.css('font-size'))         
        newfs = fs-1
        @$el.css('font-size', newfs + 'px')
        @variables.set 'fontSize', (fs-1) / @variables.get "scale"

        # Reset line height to 1.5 (font size * 1.5)
        adj = newfs * 1.5
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

        if @lastRendering?.get(0)?

          myOffset = annoEl.offset()
          # Although sublinear insertions may influence the position of superlinear insertions,
          # the opposite should not be true.
          if (@lastRendering.data("place")? and annoEl.data("place")?) and @lastRendering.data("place") == "above" and annoEl.data("place") == "below"
              middle = myOffset.left + annoEl.outerWidth(false)/2
          else if @lastRendering.hasClass 'sgaDeletionAnnotation'
            # If the previous is a deletion, stick it in the middle!
            middle = @lastRendering.offset().left + (@lastRendering.outerWidth(false)/2)
          else
            middle = @lastRendering.offset().left + (@lastRendering.outerWidth(false))
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

      # Instiate different views depending on the type of annotation.
      type = model.get "type"
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
            additionLine.append(annoEl).insertBefore(@currentLineEl)

            # If the annotation is just empty space, skip
            if annoEl.get(0)?
              setPosition(textAnnoView, annoEl) 
              @lastRendering = annoEl

          else if /vertical-align: sub;/.test(model.get("css"))
            additionLine = if not @currentLineEl.next().hasClass('below-line') \
                           then $("<div class='below-line'></div>")\
                           else @currentLineEl.next()

            textAnnoView = new TextAnnoView 
              model: model 
            annoEl = $ textAnnoView.render()?.el
            annoEl.data "place", "below"
            additionLine.append(annoEl).insertAfter(@currentLineEl)

            if annoEl.get(0)?
              setPosition(textAnnoView, annoEl) 
              @lastRendering = annoEl

          else
            textAnnoView = new TextAnnoView 
              model: model 
            @lastRendering = annoEl = $ textAnnoView.render()?.el
            @currentLineEl.append annoEl

        when "Text" in type \
        or "sgaLineAnnotation" in type \
        or "sgaDeletionAnnotation" in type \
        or "sgaSearchAnnotation" in type
          textAnnoView = new TextAnnoView 
            model: model 
          annoEl = $ textAnnoView.render()?.el          
          @currentLineEl.append annoEl
          if annoEl.get(0)?
            @lastRendering = annoEl 
        when "LineBreak" in type

          # Before creating a new line container, add other classes on the current one.
          # For example, alignment and indentation are stored on the line break annotation
          # and must be processed now.          

          if model.get("align")?
              where = model.get("align")
              # Base alignment on longest previous line if possible.
              longest = 0
              for prevLine in @currentLineEl.prevAll()
                prevLineLength = $.trim($(prevLine).text().replace(/\s+/g,' ')).length
                if prevLineLength > longest
                  longest = prevLineLength
              if longest > 0
                if where == "right"
                  padding = longest - @currentLineEl.text().length
                  @currentLineEl.css
                    'padding-left': padding + "ex"
                else if where == "center"
                  padding = longest / 2 - @currentLineEl.text().length
                  @currentLineEl.css
                    'padding-left': padding + "ex"
              # still adjust centers to an approximate value (not great, but better results)
              else if where == "center"
                  @currentLineEl.css
                    'padding-left': "15ex"
              else
                @currentLineEl.css
                  'text-align': model.get("align")
          if model.get("indent")?
            indentSize = @$el.width() / 10
            indentNo = Math.floor(model.get("indent")) or 0
            @currentLineEl.css
              'padding-left': indentNo * indentSize + "px"

            # Add indentation to interlinear additions, if present
            al = @currentLineEl.prev('.above-line,.below-line')
            if al
              al.css
                'padding-left': indentNo * indentSize + "px"

          # Only now overwrite the @currentLineEl variable
          # and add a new line container that will be populated at the next run of addOne()
          @currentLineEl = $("<div></div>")
          @$el.append @currentLineEl

          # Update currentLine count
          @currentLine += 1
          
      if @variables.get('scrollWidth') != @el.scrollWidth
        @variables.set('scrollWidth', @el.scrollWidth)

      # Update scrollbar styling if plugin exists
      if @$el.parent().perfectScrollbar?
        @$el.parent().perfectScrollbar('update')

  class TextAnnoView extends AreaView
    tagName: "span"

    render: -> 
      @$el.css 'display', 'inline-block'
      @$el.text @model.get "text"
      @$el.addClass @model.get("type").join(" ")

      icss = @model.get "css"
      if icss? and not /^\s*$/.test(icss) then @$el.attr "style", icss
      
      content = @model.get("text").replace(/\s+/g, " ")
      if content == " "
        charWidth = 0
      else
        charWidth = content.length

      if charWidth == 0
        return null

      # lines[currentLine] ?= []
      # lines[currentLine].push rendering
      # rendering.line = currentLine
      # rendering.positioned = false
      # rendering.setScale = (s) ->
      
      # rendering.afterLayout = ->
      #   rendering.width = rendering.$el.width() / that.getScale()
      
      # rendering.remove = ->
      #   el.remove()
      #   lines[rendering.line] = (r for r in lines[rendering.line] when r != rendering)

      # rendering.update = (item) ->
      #   el.text item.text[0]
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

      # Extend view properties
      @variables.set "active", false
      @variables.set "zoom", 0
      @variables.set "maxZoom", 0
      @variables.set "minZoom", 0
      @variables.set "imgPosition", {}

    render: ->
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
        vars: @variables.variables

      syncVarsFor imageControls      

      # 
      # Render tiled image, add interaction.
      #

      djatokaTileWidth = 256

      width = if @model.get('width')? then @model.get('width')
      height = if @model.get('height')? then @model.get('height')

      divScale = @variables.get("scale")
      imgScale = divScale

      innerContainer = $("<div></div>")
      @$el.append innerContainer

      $(innerContainer).css
        'overflow': 'hidden'
        'position': "absolute"
        'top': 0
        'left': '16px'

      imgContainer = $("<div></div>")
      $(innerContainer).append(imgContainer)

      @variables.set 'active', true

      baseURL = @model.get("service") + "?url_ver=Z39.88-2004&rft_id=" + @model.get("@id")

      @setZoom = (z) ->
        return

      zoomLevel = null

      offsetX = 0
      offsetY = 0

      $.ajax
        url: baseURL + "&svc_id=info:lanl-repo/svc/getMetadata"
        success: (metadata) =>
          # original{Width,Height} are the size of the full jp2 image - the maximum resolution            
          originalWidth = Math.floor(metadata.width) || 1
          originalHeight = Math.floor(metadata.height) || 1
          imgScale = width / originalWidth
          # zoomLevels are how many different times we can divide the resolution in half
          zoomLevels = Math.floor(metadata.levels)
          # div{Width,Height} are the size of the HTML <div/> in which we are rendering the image
          divWidth = @$el.width() || 1
          divHeight = @$el.height() || 1

          #divScale = @variables.get("scale")
          # {x,y}Tiles are how many whole times we can tile the <div/> with tiles _djatokaTileWidth_ wide
          xTiles = Math.floor(originalWidth * divScale * Math.pow(2.0, zoomLevel) / djatokaTileWidth)
          yTiles = Math.floor(originalHeight * divScale * Math.pow(2.0, zoomLevel) / djatokaTileWidth)
          inDrag = false
          
          # If at all needed, this should be handled with Backbone, not jQuery
          # so that we can dispose of bindings when the view is removed.
          # mouseupHandler = (e) ->
          #  if inDrag
          #    e.preventDefault()
          #    inDrag = false
          # $(document).mouseup mouseupHandler
          # Unbind event when the view is removed.
          #   $(document).unbind 'mouseup', mouseupHandler

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
          recalculateBaseZoomLevel = =>
            if @variables.get("scale")? > 0
              baseZoomLevel = Math.max(0, Math.ceil(-Math.log( @variables.get("scale") * imgScale )/Math.log(2)))
              baseZoomLevel = Math.max(0, zoomLevels - baseZoomLevel) + 1
              @variables.set 'minZoom', baseZoomLevel
              @variables.set 'maxZoom', zoomLevels

          wrapWithImageReplacement = (cb) ->
            cb()
            currentZ = Math.ceil(zoomLevel + baseZoomLevel)
            $(imgContainer).find("img").each (idx, elm) ->
              img = $(elm)
              x = img.data 'x'
              y = img.data 'y'
              z = img.data 'z'
              if z != currentZ
                img.css
                  "z-index": -10
              else
                img.css
                  "z-index": 0         

          updateImageControlPosition = =>
            @variables.set 'imgPosition',
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

          renderTile = (o) =>
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

              do (imgEl) =>
                imgEl.bind 'mousedown', (evt) ->
                  if not inDrag
                    evt.preventDefault()

                    startX = null
                    startY = null
                    startoffsetX = offsetX
                    startoffsetY = offsetY
                    inDrag = true
                    SGASharedCanvas.Utils.mouse.capture (type) ->
                      e = @
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
                          SGASharedCanvas.Utils.mouse.uncapture()

                imgEl.bind 'mousewheel DOMMouseScroll MozMousePixelScroll', (e) =>
                  e.preventDefault()
                  inDrag = false
                
                  x = e.originalEvent.offsetX + parseInt($(imgEl).css('left'), 10)
                  y = e.originalEvent.offsetY + parseInt($(imgEl).css('top'), 10)
                
                  # we want to change centerX/centerY so that scrollPoint is constant after the zoom
                  z = zoomLevel
                  oldOffsetX = offsetX
                  oldOffsetY = offsetY
                  scrollPoint = screen2original(x, y)
                  oldOffsetX -= scrollPoint.left
                  oldOffsetY -= scrollPoint.top
                  if z >= 0 and z <= zoomLevels - baseZoomLevel
                    @setZoom (z + 1) * (1 + e.originalEvent.wheelDeltaY / 500) - 1
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

          renderTiles = =>
            divWidth = @$el.width() || 1
            divHeight = @$el.height() || 1
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

          @setZoom = (z) =>
            if z != zoomLevel
              _setZoom(z)
              @variables.set "zoom", z

          setScale = (s) ->
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

          setScale divScale

          zoomLevel = 0

          Backbone.on 'viewer:resize', (options) =>
            setScale options.scale

          # Listen to Image Controls zoom value for updating
          @variables.set "lastZoom", imageControls.variables.get 'zoom'
          @listenTo imageControls.variables, 'change:zoom', (z) ->
            if z != @variables.get "lastZoom" 
              @variables.set "lastZoom", z
              @setZoom z
      @

)()