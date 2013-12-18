# # Utilities
# Useful functions to use globally in the application.

SGASharedCanvas.Utils = SGASharedCanvas.Utils or {}

( ->

	SGASharedCanvas.Utils.makeArray = (item) ->
      if !$.isArray item then [ item ] else item

  #
  # Some of our Views have properties that are not reflected in the data models. 
  # The models should be considered read-only from the views
  # 
  # In order to manage this properties, we mix Backbone's Events module
  # with the properties and define general setters and getters to fire Backbone events.
  #
  class SGASharedCanvas.Utils.AudibleProperties

    constructor: (@variables) ->
      _.extend @, Backbone.Events

    set: (prop, val) ->
      @variables[prop] = val
      @trigger 'change', @variables
      @trigger 'all', @variables
      @trigger 'change:'+prop, val, @variables

    get: (prop) ->
      if @variables[prop]? 
        @variables[prop]
      else 
        throw new Error "View property #{prop} does not exist."

)()