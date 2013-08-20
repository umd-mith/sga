# # Full Text Search

window.SGAsearch = {}

(($,SGAsearch,_,Backbone) ->

  # SearchResult
  class SGAsearch.SearchResult extends Backbone.Model
    defaults:
      "hls"   : []
      "id": "[Page]"
      "shelfmark": "[Shelfmark]"
      "title" : "[Title]"
      "nbook" : "[Notebook]"
      "author" : "[Author]"
      "editor" : "[Editor]"
      "date" : "[Date]"

  # SearchResult List
  class SGAsearch.SearchResultList extends Backbone.Collection
    model: SGAsearch.SearchResult

  class SGAsearch.SearchResultListView extends Backbone.View
    render: ->
      @collection.each @addOne, @
      @

    addOne: (model) =>
      view = new SGAsearch.SearchResultView {model: model}
      $(SGAsearch.destination).append view.render().$el

    clear: ->
      @collection.each (m) -> m.trigger('destroy')

  class SGAsearch.SearchResultView extends Backbone.View
    template: _.template $('#result-template').html()
    initialize: ->
      @listenTo @model, 'change', @render
      @listenTo @model, 'destroy', @remove

    render: ->
      @$el.html @template(@model.toJSON())
      @

    remove: ->
      @$el.remove()
      @

  SGAsearch.search = (service, query, options, destination, page = 0) ->    

    SGAsearch.destination = destination

    if @srlv?
      @srlv.clear()

    @srl = new SGAsearch.SearchResultList()
    @srlv = new SGAsearch.SearchResultListView 
      collection: @srl

    fields = "text"
    url = "#{service}?q=#{query}&f=#{fields}"

    updateResults = (res) =>
      for r in res.results
        sr = new SGAsearch.SearchResult()
        @srlv.collection.add sr

        r.num = (res.results.indexOf(r) + 1) + page*20
        r.id = r.id.substr r.id.length - 4
        r.shelfmark = r.shelfmark.substr r.shelfmark.length - 3

        sr.set r

      @srlv.render()

    $.ajax
      url: url
      type: 'GET'
      processData: false
      success: updateResults

)(jQuery,window.SGAsearch,_,Backbone)