# # Routers
# This file defines all Backbone routers (hashchange management)

SGASharedCanvas.Router = SGASharedCanvas.Router or {}

( ->

  #
  # For now, the routers assume that there is only one Manifest
  #

  class Main extends Backbone.Router
    routes:
      "" : "pageOne"
      "p:n" : "page"
      "p:n/mode/:mode" : "mode"
      "p:n/search/f\::filters|q\::query" : "search"

    pageOne: ->
      loc = Backbone.history.location.hash + "#/p1"
      Backbone.history.navigate(loc, {trigger:true})

    page: (n) ->
      n = 1 if !n? or n<1

      manifests = SGASharedCanvas.Data.Manifests
      
      # Trigger an event "page" on the manifests collection to 
      # fetch canvas data      
      manifests.trigger "page", n

    mode: (n, mode) ->
      n = 1 if !n? or n<1

      manifests = SGASharedCanvas.Data.Manifests
      
      # Trigger an event "page" on the manifests collection that 
      # includes mode info to switch to various reading modes
      manifests.trigger "page", n, {mode : mode}

    search: (n, filters, query) -> 
      n = 1 if !n? or n<1     

      manifests = SGASharedCanvas.Data.Manifests
      # Trigger an event "page" on the manifests collection that 
      # includes search info to fetch search data
      manifests.trigger "page", n, {filters : filters, query : query}

  SGASharedCanvas.Router.Main = new Main

)()