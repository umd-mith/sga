# # Utilities
# Useful functions to use globally in the application.

SGASharedCanvas.Utils = SGASharedCanvas.Utils or {}

( ->	

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

    set: (prop, val, silent=false) ->
      @variables[prop] = val
      if !silent
        @trigger 'change', @variables
        @trigger 'all', @variables
        @trigger 'change:'+prop, val, @variables

    get: (prop) ->  
      @variables[prop]

  # Embed any object in an Array, if it isn't an Array already.
  SGASharedCanvas.Utils.makeArray = (item) ->
      if !$.isArray item then [ item ] else item


  # ## Mouse capture (from MITHgrid)
  #
  # To receive notices of mouse movement and mouse button up events 
  # regardless of where they are in the document,
  # register appropriate functions.
  #
  SGASharedCanvas.Utils.mouse = 
    mouseCaptureCallbacks : []
      
    capture: (cb) ->
      oldCB = @mouseCaptureCallbacks[0]
      @mouseCaptureCallbacks.unshift cb
      if @mouseCaptureCallbacks.length == 1
        # it was zero before, so no bindings
        $(document).mousemove (e) =>
          e.preventDefault()
          @mouseCaptureCallbacks[0].call e, "mousemove"
        $(document).mouseup (e) =>
          e.preventDefault()
          @mouseCaptureCallbacks[0].call e, "mouseup"
      oldCB
    
    uncapture: ->
      oldCB = @mouseCaptureCallbacks.shift()
      if @mouseCaptureCallbacks.length == 0
        $(document).unbind "mousemove"
        $(document).unbind "mouseup"
      oldCB

)()