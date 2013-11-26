# # Model Views
# This file handles views of models and collections.

SGASharedCanvas.View = SGASharedCanvas.View or {}

( ->

	class SGASharedCanvas.Application extends Backbone.View

    initialize : (config={}) ->

      Backbone.history.start()

      manifestUrl = $(".sharedcanvas").data('manifest')
      manifest = SGASharedCanvas.Data.importFullJSONLD manifestUrl 

      # manifestView = new ManifestView model : manifest

	# Manifest view
	class ManifestView extends Backbone.View

	  # Instead of generating a new element, bind to the existing skeleton of
	  # already present in the HTML.
	  el: '#SGASharedCanvasViewer'

	  initialize: ->
	    @listenToOnce @model.canvases, 'add', @renderCanvas


	  renderCanvas: ->
	  	canvasView = new CanvasesView collection : @model.canvases

	  render: ->
	    @

	  remove: ->
	    @$el.remove()
	    @

	# Canvas view
	class CanvasView extends Backbone.View

	  initialize: ->
      console.log @model

    # render: (dest) ->
    #   @target = dest
    #   @collection.each @addOne, @
    #   @

    # addOne: (model) =>
    #   view = new SGAranges.WorkView {model: model}
    #   $(@target).append view.render().$el

    # clear: ->
    #   @collection.each (m) -> m.trigger('destroy')
  
  SGASharedCanvas.View.ClearCanvases = ->
    0

  SGASharedCanvas.View.ShowCanvas = (canvas) ->
    canvasView = new CanvasView model: canvas

)()