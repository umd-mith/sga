# # Full Text Search

window.SGAsearch = {}

(($,SGAsearch,_,Backbone) ->

## MODELS ##

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

  # Facet
  class SGAsearch.Facet extends Backbone.Model
    defaults:
      "name"   : "",
      "num"    : 0

## COLLECTIONS ##

  # SearchResult List
  class SGAsearch.SearchResultList extends Backbone.Collection
    model: SGAsearch.SearchResult

  # Facet List
  class SGAsearch.Facetlist extends Backbone.Collection
    model: SGAsearch.Facet

## VIEWS ##

  # SearchResult List View
  class SGAsearch.SearchResultListView extends Backbone.View
    target: null

    render: (dest) ->
      @target = dest
      @collection.each @addOne, @
      @

    addOne: (model) =>
      view = new SGAsearch.SearchResultView {model: model}
      $(@target).append view.render().$el

    clear: ->
      @collection.each (m) -> m.trigger('destroy')

  # SearchResult view
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

  # Facet List View
  class SGAsearch.FacetListView extends Backbone.View
    target: null

    render: (dest) ->
      @target = dest
      @collection.each @addOne, @
      @

    addOne: (model) =>
      view = new SGAsearch.FacetView {model: model}
      $(@target).append view.render().$el

    clear: ->
      @collection.each (m) -> m.trigger('destroy')

  # Face View
  class SGAsearch.FacetView extends Backbone.View
    template: _.template $('#facet-template').html()
    initialize: ->
      @listenTo @model, 'change', @render
      @listenTo @model, 'destroy', @remove

    render: ->
      @$el.html @template(@model.toJSON())
      @

    remove: ->
      @$el.remove()
      @

  SGAsearch.search = (service, query, facets, destination, page = 0) ->   

    if @srlv?
      @srlv.clear()

    @srl = new SGAsearch.SearchResultList()
    @srlv = new SGAsearch.SearchResultListView collection: @srl

    fields = "text"
    url = "#{service}?q=#{query}&f=#{fields}"

    updateResults = (res) =>
      # Results

      $(".num-results .badge").show().text res.numFound

      for r in res.results
        sr = new SGAsearch.SearchResult()
        @srlv.collection.add sr

        r.num = (res.results.indexOf(r) + 1) + page*20
        r.id = r.id.substr r.id.length - 4
        r.shelfmark = r.shelfmark.substr r.shelfmark.length - 3

        sr.set r

      @srlv.render destination

      # Facets

      ## Notebooks

      if @nb_flv?
        @nb_flv.clear()

      @nb_fl = new SGAsearch.Facetlist()
      @nb_flv = new SGAsearch.FacetListView collection: @nb_fl 

      for k,v of res.facets.notebooks
        f_nb = new SGAsearch.Facet()
        @nb_flv.collection.add f_nb

        f_nb.set
          "name" : k
          "num" : v

      @nb_flv.render $(facets).find('#r-list-notebook')

      ## Hand

      if @h_flv?
        @h_flv.clear()

      @h_fl = new SGAsearch.Facetlist()
      @h_flv = new SGAsearch.FacetListView collection: @h_fl 

      f_h_mws = new SGAsearch.Facet()
      f_h_pbs = new SGAsearch.Facet()

      @h_flv.collection.add f_h_mws
      @h_flv.collection.add f_h_pbs

      f_h_mws.set 
        "name" : "Mary Shelley"
        "num"  : res.facets.hand_mws

      f_h_pbs.set 
        "name" : "Percy Bysshe Shelley"
        "num"  : res.facets.hand_pbs      

      @h_flv.render $(facets).find('#r-list-hand')

      ## Revision

      if @r_flv?
        @r_flv.clear()

      @r_fl = new SGAsearch.Facetlist()
      @r_flv = new SGAsearch.FacetListView collection: @r_fl 

      f_add = new SGAsearch.Facet()
      f_del = new SGAsearch.Facet()

      @r_flv.collection.add f_add
      @r_flv.collection.add f_del

      f_add.set 
        "name" : "Added Passages"
        "num"  : res.facets.added

      f_del.set 
        "name" : "Deleted Passages"
        "num"  : res.facets.deleted      

      @r_flv.render $(facets).find('#r-list-rev')

    $.ajax
      url: url
      type: 'GET'
      processData: false
      success: updateResults

)(jQuery,window.SGAsearch,_,Backbone)