# # Routers
# This file defines all Backbone routers (hashchange management)

SGASharedCanvas.Router = SGASharedCanvas.Router or {}

( ->

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

    SGASharedCanvas.View.clearCanvases()

    SGASharedCanvas.Data.importCanvasData n, (canvas) ->
      SGASharedCanvas.View.showCanvas canvas


)()