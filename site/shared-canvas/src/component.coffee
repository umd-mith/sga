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

    checkAndProceed: (newPage) ->
      hash = Backbone.history.location.hash
      if hash.match("#\/?p")?
        hash = hash.replace(/#\/?p\d+/, '#/p'+newPage)
      else 
        hash = "#/p"+newPage
      return hash

    nextPage: (e) ->
      e.preventDefault()
      hash = @checkAndProceed @variables.get("seqPage")+1
      Backbone.history.navigate(hash, {trigger:true})
    prevPage: (e) ->
      e.preventDefault()
      hash = @checkAndProceed @variables.get("seqPage")-1
      Backbone.history.navigate(hash, {trigger:true})
    firstPage: (e) ->
      e.preventDefault()
      hash = @checkAndProceed @variables.get("seqMin")
      Backbone.history.navigate(hash, {trigger:true})
    lastPage: (e) ->
      e.preventDefault()
      hash = @checkAndProceed  @variables.get("seqMax")
      Backbone.history.navigate(hash, {trigger:true})

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
                newPage = (pages - ui.value) + 1
                hash = Backbone.history.location.hash
                if hash.match("#\/?p")?
                  hash = hash.replace(/#\/?p\d+/, '#/p'+newPage)
                else 
                  hash = "#/p"+newPage
                Backbone.history.navigate hash

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
      Backbone.on "viewer:searchResults", (results) =>
        # Remove existing highlights, if any
        @$el.find('.res').remove()

        # Append highglights

        pages = @variables.get "seqMax"

        try
          for r in results
            r = parseInt(r)
            res_height = @$el.height() / (pages)
            valPercent = 100 - ((r * 100) / pages)
            adjustment = 50/pages # adjust by .5% to position near middle of cursor (instead of top)
            @$el.append("<div style='bottom:#{valPercent + adjustment}%; height:#{res_height}px' class='res ui-slider-range ui-widget-header ui-corner-all'> </div>")
        catch e
          console.log "Unable to update slider with search results"

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

    initialize: (options) ->
      super          
      @listenTo SGASharedCanvas.Data.Manifests, 'page', (n, options) ->
        if options?
          if options.mode?
            switch options.mode
              when "img" then @$el.find("#img-only").button("toggle")
              else @$el.find("#mode-"+options.mode).button("toggle")
          else
            @$el.find("#mode-std").button("toggle")

    events: 
      'click #img-only': 'setImgMode'
      'click #mode-std': 'setStdMode'
      'click #mode-rdg': 'setRdgMode'
      'click #mode-xml': 'setXmlMode'

    checkAndProceed: (m) ->
      hash = Backbone.history.location.hash
      # remove search fragment if present
      hash = hash.replace(/\/search\/f:[^\|]+\|q:[^\/]+/, "")      
      if hash.match("\/mode\/")?
        hash = hash.replace(/mode\/\w{3}/, 'mode/'+m)
      else 
        hash = hash.replace(/(#\/?p\d+)/, '$1/mode/'+m)
      return hash

    setImgMode: (e) ->
      e.preventDefault()
      hash = @checkAndProceed "img"
      Backbone.history.navigate(hash, {trigger:true})
    setStdMode: (e) ->
      e.preventDefault()
      hash = @checkAndProceed "std"
      Backbone.history.navigate(hash, {trigger:true})
    setRdgMode: (e) ->
      e.preventDefault()
      hash = @checkAndProceed "rdg"
      Backbone.history.navigate(hash, {trigger:true})
    setXmlMode: (e) ->
      e.preventDefault()
      hash = @checkAndProceed "xml"
      Backbone.history.navigate(hash, {trigger:true})


  class SGASharedCanvas.Component.LimitViewControls extends ComponentView

    initialize: (options) ->
      super

      # set css classes scope to be limited from options
      @limitValues = [].concat options.include
      # set colors for visible and limited objects
      @colors = options.colors
      @colors = {} if !@colors?
      if !@colors.visible?
        @colors.visible = '#a54647'
      if !@colors.limited?
        @colors.limited = '#D9D9D9'
      # set a default limiter if specified. 
      # elements outside of the classes scope will be kept visible when 
      # the default limiter is selected.
      @defLimiter = options.defLimiter

      # set css classes scope to be limited from HTML template
      @$el.find('input').each (i,e) =>
        vals = $(e).val()
        vals = vals.split /\s+/g
        for v in vals
          if v != 'all'
            @limitValues.push v

      # Apply css to limited and visible object according to selected class
      @$el.change (e) =>
        checked = $(e.target).val()
        checked = checked.split /\s+/g

        # Remove limit view css if present
        $('#LimitViewControls_classes').remove()

        if 'all' not in checked

          css = ""
          hide = ""

          for c in checked
            # Show
            css += " .sharedcanvas[data-types] .#{c} { color: #{@colors.visible} }"          

            # If this is the default delimiter, make elements outside of class scope visible.
            # Also, create a css declaration for each limiter in the scope
            if checked.length == 1 and c == @defLimiter
              for limit in @limitValues
                css += " .sharedcanvas[data-types] .#{limit} { color: #{@colors.limited} }"
                css += " .sharedcanvas[data-types] *:not(.#{limit}) { color: #{@colors.visible} }"
            # If not, then just hide everything that is not in our limiter's class
            else
              hide += ":not(.#{c})"              

          css += " .sharedcanvas[data-types] *#{hide} { color: #{@colors.limited} }"
          
          # Append new style definitions to head
          $("<style type='text/css' id='LimitViewControls_classes'>#{css}</style>").appendTo("head")

  class SGASharedCanvas.Component.SearchBox extends ComponentView

    events: 
      'submit': 'search'
      'click #searchbtn': 'submitForm'

    search: (e) ->
      e.preventDefault()
      loc = Backbone.history.fragment

      fields_html = $(e.target).find('#limit-search input:checked')
      fields = ""
      if fields_html.length == 0
        fields = "text"
      else
        for f,i in fields_html
          fields += $(f).val()
          if i+1 != fields_html.length
            fields +=  ','
      val = @$el.find("input#searchbox").val()
      if !val.match '^\s*$'
        q = "f:"+fields+"|q:"+val

        # remove search fragment if present
        loc = loc.replace(/\/search\/f:[^\|]+\|q:[^\/]+/, "")

        # remove mode fragment if present
        loc = loc.replace(/\/mode\/\w{3}/, "")

        Backbone.history.navigate(loc+'/search/'+q, {trigger:true})
      false

    submitForm: (e) ->
      e.preventDefault()
      @$el.submit()
      
)()