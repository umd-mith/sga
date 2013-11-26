# # Routers
# This file defines all Backbone routers (hashchange management)

SGASharedCanvas.Router = SGASharedCanvas.Router or {}

( ->

  manifests = SGASharedCanvas.Data.Manifests

  #
  # For now, the routers assume that there is only one Manifest
  #

  class Pagination extends Backbone.Router
    routes:
      "" : "page"
      "page/:n" : "page"

  SGASharedCanvas.Router.Pagination = new Pagination

  SGASharedCanvas.Router.Pagination.on 'route:page', (n) ->    
    n = 1 if !n? or n<1

    # destroy current canvas view, if any
    SGASharedCanvas.View.ClearCanvases()

    manifest = manifests.first()
    if manifest?
      canvas = SGASharedCanvas.Data.getCanvasFor 'first', n
      canvasView = SGASharedCanvas.View.ShowCanvas canvas
    else 
      manifests.once "add", ->        
        manifest = this.first()
        manifest.once "sync", ->
          canvas = SGASharedCanvas.Data.getCanvasFor 'first', n
          SGASharedCanvas.Data.importCanvasData canvas
          canvasView = SGASharedCanvas.View.ShowCanvas canvas
)()