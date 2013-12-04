# # Model Views
# This file handles views of models and collections.

SGASharedCanvas.View = SGASharedCanvas.View or {}

( ->

  # MAIN APPLICATION VIEW
	class SGASharedCanvas.Application extends Backbone.View

    initialize: (config={}) ->     

      manifestUrl = $("#SGASharedCanvasViewer").data('manifest')
      # manifest = SGASharedCanvas.Data.importFullJSONLD manifestUrl 

      # Instantiate manifests collection and view
      manifests = SGASharedCanvas.Data.Manifests
      manifestsView = new ManifestsView collection : manifests
      # Add manifest from DOM. This triggers data collection and rendering.
      manifest = manifests.add
        url: manifestUrl
      manifest.fetch()      

      # Activate Routers
      Backbone.history.start()

  #
  # Our Views have properties that are not reflected in the data models. 
  # The models should be considered read-only from the views
  # 
  # In order to manage this properties, we mix Backbone's Events module
  # with the properties and define general setters and getters to fire Backbone events.
  #
  class ViewProperties

    constructor: (@variables) ->
      _.extend @, Backbone.Events

    set: (prop, val) ->
      if @variables[prop]?
        @variables[prop] = val
        @trigger 'change', @variables
        @trigger 'all', @variables
        @trigger 'change:'+prop, val, @variables
      else 
        throw new Error "View property #{prop} does not exist."

    get: (prop) ->
      if @variables[prop]? 
        @variables[prop]
      else 
        throw new Error "View property #{prop} does not exist."

  # Manifests view
  class ManifestsView extends Backbone.View

    # Instead of generating a new element, bind to the existing skeleton of
    # already present in the HTML.
    el: '#SGASharedCanvasViewer'

    initialize: ->
      @listenTo @collection, 'add', @addOne

    addOne: (model) ->
      manifestView = new ManifestView model: model

    render: ->
      @

    remove: ->
      @$el.remove()
      @

  # Manifest view
  class ManifestView extends Backbone.View

    initialize: ->
      # Add views for child collections right away
      canvasesView = new CanvasesView collection: @model.canvases

      # When a new canvas is requested through a Router, fetch the right canvas data.
      @listenTo SGASharedCanvas.Data.Manifests, 'page', (n) ->

        fetchCanvas = =>
          # For now we assume there is only one sequence.
          # Eventually this should be on a sequence view.
          canvases = @model.sequences.first().get "canvases"
          n = canvases.length if n > canvases.length
          # Locate requested canvas Backbone object
          canvas =  @model.canvases.get canvases[n-1]
          # Create the view
          canvasesView.showCanvas canvas
          # Finally fetch the data. This will cause the views to render.
          canvas.fetch @model

        # Make sure manifest is loaded        
        if @model.sequences.length > 0
          fetchCanvas()
        else
          @model.once "sync", fetchCanvas

    render: ->
      @

    remove: ->
      @$el.remove()
      @

  # Canvases view
  class CanvasesView extends Backbone.View

    initialize: ->
      # Keep track of canvas views for caching.
      @views = {}

    detachAll: () ->
      # Detach from DOM views for each canvas model, 
      # but keep them cached

    showCanvas: (c) ->
      cid = c.get "@id"
      if @views[cid]?
        #refresh/reattach view
        console.log "we're back! reattaching", cid
      else # when the data for canvas is fetched the first time
        @views[cid] = new CanvasView model: c

    render: ->
      @

    remove: ->
      @$el.remove()
      @

  # Canvas view
  class CanvasView extends Backbone.View

    # Instead of generating a new element, bind to the existing skeleton of
    # already present in the HTML.
    el: '#mainSharedCanvas'

    initialize: ->
      # Here we collect data-types expressed in HTML and
      # we organize further collections according to them.

      areas = []

      $(@el).find('.sharedcanvas').each ->
        data = $(@).data()
        data["el"] = @
        areas.push data

      for area in areas
        for type in area.types.split(" ")
        # Accepted data-types "All", "Image", "Text". 
        # Eventually Audio, Video, NotatedMusic...
          switch type
            when "All"
              new ContentsView 
                collection: @model.contents
                el: area.el
              # new ImagesView
            when "Image"
              0 # new ImagesView
            when "Text"
              new ContentsView 
                collection: @model.contents
                el: area.el
        # Finally, we use canvas data to render sub-views for the areas.
        # Each is an independent view on the canvas data.
        areaView = new ViewerAreaView 
          model: @model
          el: area.el

    detach: ->
      # Detach and unbind this view from the DOM,
      # but don't destroy it.
      @

    render: ->
      @

    remove: ->
      @$el.remove()
      @

  # ViewerArea View
  class ViewerAreaView extends Backbone.View

    initialize: ->

      # Set view properties
      @variables = new ViewProperties 
        height: 0
        width : 0
        x     : 0
        y     : 0
        scale : 0

      # Example of listeners
      # @variables.on 
      #   'change:width' : -> console.log 'w'
      #   'change:height' : -> console.log 'h'

      @render()

    render: (container) ->
      @$el.css 'overflow': 'hidden'

      container = $("<div></div>")
      @$el.append(container)
      $(container).height(Math.floor(@$el.width() * 4 / 3))
      $(container).css
        'background-color': 'white'
        'z-index': 0

      canvasWidth = null
      canvasHeight = null

      # Is this needed??
      baseFontSize = 150 # in terms of the SVG canvas size - about 15pt
      DivHeight = null
      DivWidth = Math.floor(@$el.width()*20/20)
      @$el.height(Math.floor(@$el.width() * 4 / 3))

      # Needed? Bootstrap already acts responsively...
      resizer = =>
        DivWidth = Math.floor(@$el.width()*20/20,10)
        if canvasWidth? and canvasWidth > 0
          @variables.set 'scale', DivWidth / canvasWidth
        if canvasHeight? and canvasHeight > 0
          @$el.height(DivHeight = Math.floor(canvasHeight * @variables.get 'scale'))

      $(window).on "resize", resizer

      container.css
        'border': '1px solid grey'
        'background-color': 'white'

      @listenTo @variables, 'change:scale', (s) ->
        if canvasWidth? and canvasHeight?
          DivHeight = Math.floor(canvasHeight * s)
        container.css
          'font-size': (Math.floor(baseFontSize * s * 10) / 10) + "px"
          'line-height': (Math.floor(baseFontSize * s * 11.5) / 10) + "px"
          'height': DivHeight
          'width': DivWidth

      canvasWidth = if @model.get("width")? then @model.get("width") else 0
      canvasHeight = if @model.get("height")? then @model.get("height") else 0
      resizer()

      @variables.set 'height', canvasHeight
      @variables.set 'width', canvasWidth
      @variables.set 'x', @model.get("x") if @model.get("x")?
      @variables.set 'y', @model.get("y") if @model.get("y")?
      @

  # Contents view
  class ContentsView extends Backbone.View

    initialize: ->
      @listenTo @collection, 'add', @addOne

    addOne: (model) ->
      console.log 'some content has been added and is ready to be shown'
      contentView = new ContentView model: model      

    render: ->
      @

    remove: ->
      @$el.remove()
      @

  # Content view
  class ContentView extends Backbone.View

    initialize: ->
      @render()      

    render: ->
      @

    remove: ->
      @$el.remove()
      @

)()