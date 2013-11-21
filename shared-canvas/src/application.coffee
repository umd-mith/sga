# # Application
# This file ties in everything together.

SGASharedCanvas.Application = SGASharedCanvas.Application or {}

( ->

  SGASharedCanvas.Application.start = (config={}) ->

    Backbone.history.start()

    addView = (el) ->
      manifestUrl = $(el).data('manifest')
      manifest = SGASharedCanvas.Data.importFullJSONLD manifestUrl      

    #
    # Now we go through and find all of the DOM elements that should be
    # made into shared canvas viewers.
    # Manifests with the same URL will only be loaded once.
    #
    config.class ?= ".sharedcanvas"
    $(config.class).each (idx, el) -> addView el
  
)()