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
      "type"   : ""
      "field"  : ""
      "name"   : ""
      "num"    : 0

  # Pages
  class SGAsearch.Pages extends Backbone.Model
    defaults:
      "first"  : "disabled"
      "prev"   : "disabled"
      "next"   : "disabled"
      "last"   : "disabled"
      "pages"      : 1
      "current"    : 1

## COLLECTIONS ##

  # SearchResult List
  class SGAsearch.SearchResultList extends Backbone.Collection
    model: SGAsearch.SearchResult

  # Facet List
  class SGAsearch.Facetlist extends Backbone.Collection
    model: SGAsearch.Facet

## VIEWS ##

  class SGAsearch.PagesView extends Backbone.View
    template: _.template $('#pagi-template').html()
    initialize: ->
      @listenTo @model, 'change', @render
      @listenTo @model, 'destroy', @remove

    render: ->
      @$el.html @template(@model.toJSON())
      @

    remove: ->
      @$el.remove()
      @

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

    render: (dest, o) ->
      @target = dest
      @collection.each ((m) -> @addOne(m, o)), @
      @

    addOne: (model, o) ->
      view = new SGAsearch.FacetView {model: model}
      $(@target).append view.render().$el
      @bindFacetControls view, o

    bindFacetControls: (view, o) ->
      view.$el.click (e) ->
        e.preventDefault()
        if view.model.attributes.type == 'notebook'
          o.filters = "shelfmark:#{view.model.attributes.name}"
        else
          o.fields += ",#{view.model.attributes.field}"
        SGAsearch.search(o.service, o.query, o.facets, o.destination, o.fields, 0, o.filters)

      view.$el.find('span.label-danger').click (e) ->
        e.preventDefault()
        e.stopPropagation()
        if view.model.attributes.type == 'notebook'
          f = "NOT%20shelfmark:#{view.model.attributes.name}"
          if !o.filters? 
            o.filters = f 
          else 
            o.filters += ",#{f}"
        else
          o.fields += ",NOT%20#{view.model.attributes.field}"
        SGAsearch.search(o.service, o.query, o.facets, o.destination, o.fields, 0, o.filters)

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

  SGAsearch.search = (service, query, facets, destination, fields = 'text', page = 0, filters=null, sort=null) ->   

    srcOptions = 
      service : service
      fields : fields
      query : query
      facets : facets
      destination : destination
      page : page
      filters : filters
      srt: sort

    if @srlv?
      @srlv.clear()

    @srl = new SGAsearch.SearchResultList()
    @srlv = new SGAsearch.SearchResultListView collection: @srl

    url = "#{service}?q=#{query}&f=#{fields}"

    if filters?
      url += "&filters=#{filters}"

    if page > 0
      url += "&s=#{page*20}"

    if sort?
      url += "&sort=#{sort}"

    console.log url

    bindSort = () ->
      sortBy = $(".r-sorting").find('[name=r-sortby]')
      order = $(".r-sorting").find('[name=r-sort]')

      sortSearch = ->
        sv = sortBy.val()
        ov = order.val()
        o = srcOptions
        o.srt = "#{sv}%20#{ov},id%20#{ov}"
        SGAsearch.search(o.service, o.query, o.facets, o.destination, o.fields, o.page, o.filters, o.srt)

      sortBy.change ->
        sortSearch()
        
      order.change ->
        sortSearch()

    bindPagination = (tot) ->
      pages = Math.ceil tot/20
      pagi = new SGAsearch.Pages()
      current = page+1

      first = "disabled"
      prev = "disabled"
      next = "disabled"
      last = "disabled"

      if current > 1
        first = ""
        prev = ""
      else if current < pages
        next = ""
        last = ""

      pagi.set
        "first"  : first
        "prev"   : prev
        "next"   : next
        "last"   : last
        "pages"      : pages
        "current"    : current

      view = new SGAsearch.PagesView {model: pagi}
      view.setElement $(".pagination-sm")
      view.render().$el

      view.$el.find('a:not(.dots)').each (i,el) ->
        $(el).click (ev) ->
          ev.preventDefault()
          o = srcOptions
          btn = $(@)
          o.page = switch
            when btn.hasClass('nav-first') then 0
            when btn.hasClass('nav-prev') then current - 2
            when btn.hasClass('nav-next') then current
            when btn.hasClass('nav-last') then pages - 1
            else btn.attr("name") - 1
          SGAsearch.search(o.service, o.query, o.facets, o.destination, o.fields, o.page, o.filters)

      view.$el.find('.nav-first')

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

      # sort notebook facet by frequency
      orderedNBs = ([k, v] for k, v of res.facets.notebooks).sort (a, b) ->
        b[1] - a[1]
      .map (n) -> n[0]

      # create models and add them to collection in the right order
      for nb in orderedNBs
        f_nb = new SGAsearch.Facet()
        @nb_flv.collection.add f_nb
        
        f_nb.set
          "type" : "notebook"
          "field" : "shelfmark"
          "name" : nb
          "num" : res.facets.notebooks[nb]

      @nb_flv.render $(facets).find('#r-list-notebook'), srcOptions

      ## Hand

      if @h_flv?
        @h_flv.clear()

      @h_fl = new SGAsearch.Facetlist()
      @h_flv = new SGAsearch.FacetListView collection: @h_fl 

      if parseInt(res.facets.hand_mws) > 0
        f_h_mws = new SGAsearch.Facet()
        @h_flv.collection.add f_h_mws
        f_h_mws.set 
          "type" : "hand"
          "field" : "hand_mws"
          "name" : "Mary Shelley"
          "num"  : res.facets.hand_mws

      if parseInt(res.facets.hand_pbs) > 0
        f_h_pbs = new SGAsearch.Facet()      
        @h_flv.collection.add f_h_pbs
        f_h_pbs.set 
          "type" : "hand"
          "field" : "hand_pbs"
          "name" : "Percy Bysshe Shelley"
          "num"  : res.facets.hand_pbs      

      @h_flv.render $(facets).find('#r-list-hand'), srcOptions

      ## Revision

      if @r_flv?
        @r_flv.clear()

      @r_fl = new SGAsearch.Facetlist()
      @r_flv = new SGAsearch.FacetListView collection: @r_fl 

      if parseInt(res.facets.added) > 0
        f_add = new SGAsearch.Facet()
        @r_flv.collection.add f_add
        f_add.set 
          "type" : "rev"
          "field" : "added"
          "name" : "Added Passages"
          "num"  : res.facets.added

      if parseInt(res.facets.deleted) > 0
        f_del = new SGAsearch.Facet()      
        @r_flv.collection.add f_del
        f_del.set 
          "type" : "rev"
          "field" : "deleted"
          "name" : "Deleted Passages"
          "num"  : res.facets.deleted      

      @r_flv.render $(facets).find('#r-list-rev'), srcOptions

      # Connect UI components
      bindPagination res.numFound
      bindSort()

    $.ajax
      url: url
      type: 'GET'
      processData: false
      success: updateResults

)(jQuery,window.SGAsearch,_,Backbone)