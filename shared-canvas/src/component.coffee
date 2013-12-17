# # Component Views
# This file handles view for UI components that will be mounted as subviews.

SGASharedCanvas.Component = SGASharedCanvas.Component or {}

( ->

  class ComponentView extends Backbone.View

    initialize: (options) ->
      # Set view properties
      @variables = new ComponentProperties {}

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
      console.log newPage
      Backbone.history.navigate("#/page/"+newPage)
    prevPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqPage")-1
      Backbone.history.navigate("#/page/"+newPage)
    firstPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqMin")
      Backbone.history.navigate("#/page/"+newPage)
    lastPage: (e) ->
      e.preventDefault()
      newPage = @variables.get("seqMax")
      Backbone.history.navigate("#/page/"+newPage)

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

  class ComponentProperties

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