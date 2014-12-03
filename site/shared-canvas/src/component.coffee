# # Component Views
# This file handles view for UI components that will be mounted as subviews.

SGASharedCanvas.Component = SGASharedCanvas.Component or {}

( ->

  class ComponentView extends Backbone.View

    initialize: (options) ->
      # Set view properties
      @variables = new SGASharedCanvas.Utils.AudibleProperties {}

      # Set values if provided
      if options.vars? and typeof options.vars == 'object'
        for k, v of options.vars
          @variables.set k, v

  class SGASharedCanvas.Component.Pager extends ComponentView

    events: 
      'click #next-page': 'nextPage'
      'click #prev-page': 'prevPage'
      'click #first-page': 'firstPage'
      'click #last-page': 'lastPage'

    nextPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqPage")+1
      hash = "#/p"+newPage
      if Backbone.history.location.hash.indexOf("#/p") > -1
        hash = Backbone.history.location.hash.replace(/#\/p\d+/, '#/p'+newPage)
      Backbone.history.navigate hash
    prevPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqPage")-1
      hash = "#/p"+newPage
      if Backbone.history.location.hash.indexOf("#/p") > -1
        hash = Backbone.history.location.hash.replace(/#\/p\d+/, '#/p'+newPage)
      Backbone.history.navigate hash
    firstPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqMin")
      hash = "#/p"+newPage
      if Backbone.history.location.hash.indexOf("#/p") > -1
        hash = Backbone.history.location.hash.replace(/#\/p\d+/, '#/p'+newPage)
      Backbone.history.navigate hash
    lastPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqMax")
      hash = "#/p"+newPage
      if Backbone.history.location.hash.indexOf("#/p") > -1
        hash = Backbone.history.location.hash.replace(/#\/p\d+/, '#/p'+newPage)
      Backbone.history.navigate hash

    initialize: (options) ->
      super    

      firstEl = @$el.find('#first-page')
      prevEl = @$el.find('#prev-page')
      nextEl = @$el.find('#next-page')
      lastEl = @$el.find('#last-page')

      @listenTo @variables, 'change:seqPage', (n) ->
        if n > @variables.get "seqMin"
          firstEl.removeClass "disabled"
          prevEl.removeClass "disabled"
        else
          firstEl.addClass "disabled"
          prevEl.addClass "disabled"

        if n < @variables.get "seqMax"
          nextEl.removeClass "disabled"
          lastEl.removeClass "disabled"
        else
          nextEl.addClass "disabled"
          lastEl.addClass "disabled"    

  class SGASharedCanvas.Component.Slider extends ComponentView

    initialize: (options) ->
      super

      @data = options.data

      @listenTo @variables, 'change:seqMax', (n) ->

        getLabel = (n) =>
          # For now we assume there is only one sequence.
          # Eventually this should be on a sequence view.
          # From the sequence, we locate the correct canvas id
          sequence = @data.sequences.first()
          canvases = sequence.get "canvases"
          canvasId = canvases[n]
          canvas = @data.canvasesMeta.get canvasId
          canvas.get "sga:folioLabel"

        try 
          if @$el.data( "ui-slider" ) # Is the container set?
            @$el.slider
              max : n
          else
            pages = n
            @$el.slider
              orientation: "vertical"
              range: "min"
              min: @variables.get 'seqMin' 
              max: pages
              value: pages
              step: 0
              slide: ( event, ui ) ->
                $(ui.handle).text(getLabel(pages - ui.value))
              stop: ( event, ui ) ->
                newPage =  pages - ui.value
                Backbone.history.navigate("#/p"+(newPage+1))

            @listenTo @variables, "change:seqPage", (n) ->
              @$el.find("a").text( getLabel(n-1) )
        
            # Using the concept of "Event aggregation" (similar to the dispatcher in Angles)
            # cfr.: http://addyosmani.github.io/backbone-fundamentals/#event-aggregator
            Backbone.on 'viewer:resize', (options) =>
              @$el.height(options.container.height() + 'px')

        catch e
          console.log e, "Unable to update maximum value of slider"

      @listenTo @variables, 'change:seqMin', (n) ->
        try 
          if @$el.data( "ui-slider" ) # Is the container set?
            @$el.slider
              min : n
        catch e
          console.log e, "Unable to update minimum value of slider"

      @listenTo @variables, 'change:seqPage', (n) ->
        try 
          if @$el.data( "ui-slider" ) # Is the container set?
            @$el.slider
              value: @variables.get('seqMax') - (n-1) # The value passed in is human readable. Remove 1.
          if options.getLabel?
            @$el.find("a").text(getLabel(n))
        catch e
          console.log e, "Unable to update value of slider"

      # Draw search result indicators
      # Backbone.on "viewer:searchResults", (results) =>
      #   # Remove existing highlights, if any
      #   @$el.find('.res').remove()

      #   # Append highglights

      #   pages = @variables.get "seqMax"

      #   try
      #     for r in results
      #       r = r
      #       res_height = @$el.height() / (pages)
      #       res_h_perc = (pages) / 100
      #       s_min = @$el.slider("option", "min")
      #       s_max = @$el.slider("option", "max")
      #       valPercent = 100 - (( r - s_min ) / ( s_max - s_min )  * 100)
      #       adjustment = res_h_perc / 2
      #       # console.log valPercent
      #       @$el.append("<div style='bottom:#{valPercent + adjustment}%; height:#{res_height}px' class='res ui-slider-range ui-widget-header ui-corner-all'> </div>")
      #   catch e
      #     console.log "Unable to update slider with search results"

  class SGASharedCanvas.Component.ImageControls extends ComponentView

    events: 
      'click #zoom-reset': 'zoomReset'
      'click #zoom-in': 'zoomIn'
      'click #zoom-out': 'zoomOut'

    zoomReset: (e) ->
      e.preventDefault()
      @variables.set "zoom", 0


    zoomIn: (e) ->
      e.preventDefault()
      zoom = @variables.get "zoom"
      range = @variables.get("maxZoom") - @variables.get("minZoom")
      if Math.floor zoom+1 <= range
        @variables.set "zoom", Math.floor zoom+1

    zoomOut: (e) ->
      e.preventDefault()
      zoom = @variables.get "zoom"
      range = @variables.get("maxZoom") - @variables.get("minZoom")
      if Math.floor zoom-1 > 0
        @variables.set "zoom", Math.floor zoom-1
      else 
        @variables.set "zoom", 0

  class SGASharedCanvas.Component.ReadingModeControls extends ComponentView

    initialize: ->
      super
      @manifests = SGASharedCanvas.Data.Manifests

    events: 
      'click #img-only': 'setImgMode'
      'click #mode-std': 'setStdMode'
      'click #mode-rdg': 'setRdgMode'
      'click #mode-xml': 'setXmlMode'

    setImgMode: (e) ->
      e.preventDefault()
      @manifests.trigger "readingMode", 'img'

    setStdMode: (e) ->
      e.preventDefault()
      @manifests.trigger "readingMode", 'std'

    setRdgMode: (e) ->
      e.preventDefault()
      @manifests.trigger "readingMode", 'std'

      curCanvas = @manifests.first().canvasesData.first()

      layerAnnos = curCanvas.layerAnnos.find (m) ->
            return m.get("sc:motivatedBy")["@id"] == "sga:reading"

      $.get layerAnnos.get("resource"), ( data ) ->    
        d = $.parseHTML data
        for e in d
          if $(e).is('div')
            curCanvas.trigger "addLayer", "Text", e

    setXmlMode: (e) ->
      e.preventDefault()
      @manifests.trigger "readingMode", 'std'

      curCanvas = @manifests.first().canvasesData.first()

      layerAnnos = curCanvas.layerAnnos.find (m) ->
            return m.get("sc:motivatedBy")["@id"] == "sga:source"

      $.get layerAnnos.get("resource"), ( data ) ->    
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


  class SGASharedCanvas.Component.LimitViewControls extends ComponentView

    initialize: (options) ->
      super

      # set css classes scope to be limited from options
      @limitValues = [].concat options.include
      # set colors for visible and limited objects
      @colors = options.colors
      @colors = {} if !@colors?
      if !@colors.visible?
        @colors.visible = '#131374'
      if !@colors.limited?
        @colors.limited = '#D9D9D9'
      # set a default limiter if specified. 
      # elements outside of the classes scope will be kept visible when 
      # the default limiter is selected.
      @defLimiter = options.defLimiter

      # set css classes scope to be limited from HTML template
      @$el.find('input').each (i,e) =>

  class SGASharedCanvas.Component.SearchBox extends ComponentView

    events: 
      'submit': 'search'
      'click #searchbtn': 'submitForm'

    search: (e) ->
      e.preventDefault()
      loc = Backbone.history.fragment

      q = @$el.find("input#searchbox").val()

      # remove search fragment if present
      loc = loc.replace(/\/search\/f:[^\|]+\|q:[^\/]+/, "")

      Backbone.history.navigate(loc+'/search/f:text|q:'+q, {trigger:true})

    submitForm: (e) ->
      e.preventDefault()
      @$el.submit()
      
)()