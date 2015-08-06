# # Full Text Search

## HTML TEMPLATES LOCATED AT /_pages/search.html

window.SGAsearch = {}

(($,SGAsearch,_,Backbone) ->

## HISTORY UTILS ##

  # This may be better implemented with a router, eventualy.
  SGAsearch.History = {}

  SGAsearch.History.getState = (s) ->
    current = Backbone.history.getFragment()
    re = new RegExp s+"=([^&]+)" 
    state = re.exec(current)
    
    if state? then state[1] else state

  SGAsearch.History.setState = (states, trigger=true) ->
    # Set new fragment with new parameters
    hash = "#"
    for k, v of states
      if hash != "#"
        hash += "&"
      hash += k + "=" + v
    Backbone.history.navigate(hash, {"trigger" : trigger})

  SGAsearch.History.pushState = (states, trigger=true) ->
    # Append new or replace existing fragment parameter 
    hash = Backbone.history.getFragment()
    for k, v of states
      newparam = if hash != "" then "&" else ""
      newparam += k + "=" + v
      re = new RegExp "(&?"+k+"=)[^&]+"
      current = re.exec(hash)
      if current?
        hash = hash.replace(re, newparam)
      else
        hash += newparam
    Backbone.history.navigate(hash, {"trigger" : trigger})

  SGAsearch.History.removeState = (s, trigger=true) ->
    # Remove existing fragment parameter
    hash = Backbone.history.getFragment()
    re = new RegExp "&?"+s+"=[^&]+"
    hash = hash.replace(re, "")
    Backbone.history.navigate(hash, {"trigger" : trigger})

## MODELS ##

  # SearchResult
  class SGAsearch.SearchResult extends Backbone.Model
    defaults:
      "hls"         : []
      "id"          : ""
      "shelfmark"   : ""
      "work"        : ""
      "authors"     : ""
      "viewer_url"   : ""
      "imageURL"    : "http://placehold.it/75x100"
      "detailQuery" : ""

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
      $(@target).find('.list-group').append view.render().$el
      @bindFacetControls view, o

    bindFacetControls: (view, o) ->
      view.$el.click (e) ->
        e.preventDefault()
        f = ""
        if view.model.attributes.type == 'notebook'
          f = "shelfmark:%22#{view.model.attributes.name}%22"
        else if view.model.attributes.type == 'sketch'
          f = "has_figure:true"
        else
          # Append field if new
          re = new RegExp view.model.attributes.field
          if o.fields.search(re) == -1
            o.fields += ",#{view.model.attributes.field}"          

        if !o.filters? 
            o.filters = f 
          else 
            o.filters += ",#{f}"

        SGAsearch.search(o.service, o.query, o.facets, o.destination, o.fields, 0, o.filters)

      view.$el.find('span.label-danger').click (e) ->
        e.preventDefault()
        e.stopPropagation()
        f = ""
        if view.model.attributes.type == 'notebook'
          f = "NOT%20shelfmark:%22#{view.model.attributes.name}%22"
        else if view.model.attributes.type == 'sketch'
          f = "has_figure:false"
        else
          o.fields += ",NOT%20#{view.model.attributes.field}"

        if !o.filters? 
            o.filters = f 
          else 
            o.filters += ",#{f}"

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

  ## HISTORY ##

  SGAsearch.updateSearch = (service, facets, destination) ->

    doSearch = ->

      current = Backbone.history.getFragment()
      q = SGAsearch.History.getState("q")
      f = SGAsearch.History.getState("f")
      p = SGAsearch.History.getState("p")
      fl = SGAsearch.History.getState("fl")
      # Leaving sorting out
      s = SGAsearch.History.getState("s")

      if q? and f?
        if !p? then p = 0 else p -= 1 
        if !fl? then fl = null
        SGAsearch.search(service, q, facets, destination, f, p, fl)
        $('#all-results').show()

    doSearch()

    $(window).bind "hashchange", (e) ->
      doSearch()
      

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

    setHistory = () ->
      SGAsearch.History.pushState
        "f": fields
        "q": query

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
      if current < pages
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

    setHistory = () ->
      cur_q = SGAsearch.History.getState('q')
      cur_f = SGAsearch.History.getState('f')
      cur_p = SGAsearch.History.getState('p')
      cur_fl = parseInt SGAsearch.History.getState('fl') - 1
      if cur_q != query or cur_f != fields
        SGAsearch.History.pushState
          "q": query
          "f": fields
      if cur_p != page
        if page > 0
          SGAsearch.History.pushState
            "p": page + 1
        else 
          SGAsearch.History.removeState('p')
      if cur_fl != filters
        if filters?
          SGAsearch.History.pushState
            "fl": filters
        else
          SGAsearch.History.removeState('fl')

    updateResults = (res) =>
      # Results

      $(".num-results .badge").show().text res.numFound

      # User messages
      $("#usr-msg").hide()
      if res.numFound == 0
        $("#usr-msg").show().find('span').text "No results found."

      for r in res.results
        sr = new SGAsearch.SearchResult()
        @srlv.collection.add sr

        orig_id = r.id

        r.num = (res.results.indexOf(r) + 1) + page*20
        r.id = r.id.substr r.id.length - 4
        # r.shelfmark = r.shelfmark.substr r.shelfmark.length - 3

        r.imageURL = "http://tiles2.bodleian.ox.ac.uk:8080/adore-djatoka/resolver?url_ver=Z39.88-2004&rft_id=http://shelleygodwinarchive.org/images/ox/#{orig_id}.jp2&svc_id=info:lanl-repo/svc/getRegion&svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000&svc.format=image/jpeg&svc.level=0&svc.region=0,0,100,75"
        r.detailQuery = "/search/f:#{fields}|q:#{query}"

        sr.set r

      @srlv.render destination

      # Facets

      ## Manuscripts

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

      ## Works

      if @w_flv?
        @w_flv.clear()

      @w_fl = new SGAsearch.Facetlist()
      @w_flv = new SGAsearch.FacetListView collection: @w_fl       

      # Get work facets
      works = {}
      for fct, v of res.facets
        if fct.match(/^work_/)
          works[fct] = v

      # sort work facet by frequency
      orderedWs = ([k, v] for k, v of works).sort (a, b) ->
        b[1] - a[1]
      .map (n) -> n[0]

      # create models and add them to collection in the right order
      for w in orderedWs
        if works[w] > 0

          # Rebuild title (ish)
          title = w.replace("work_", "").replace(/_/g, " ").replace(/\ss\s/g, "'s ")
          title = title.replace(/\w\S*/g, (txt) -> txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase())

          f_w = new SGAsearch.Facet()
          @w_flv.collection.add f_w

          f_w.set
            "type" : "work"
            "field" : w
            "name" : title
            "num" : works[w]   

      @w_flv.render $(facets).find('#r-list-work'), srcOptions

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

      ## Sketches

      if @sk_flv?
        @sk_flv.clear()

      @sk_fl = new SGAsearch.Facetlist()
      @sk_flv = new SGAsearch.FacetListView collection: @sk_fl       

      if parseInt(res.facets.has_figure) > 0
        f_sk = new SGAsearch.Facet()
        @sk_flv.collection.add f_sk
        f_sk.set 
          "type" : "sketch"
          "field" : "sketch"
          "name" : "Pages with sketches"
          "num"  : res.facets.has_figure

      @sk_flv.render $(facets).find('#r-list-sketches'), srcOptions

      # Connect UI components
      bindPagination res.numFound
      bindSort()
      setHistory()

      # Track history
      setHistory()

    $.ajax
      url: url
      type: 'GET'
      processData: false
      success: updateResults
      error: -> $("#usr-msg").show().find('span').toggleClass('alert-info alert-danger').text 'Could not reach server. Please try again later.'

)(jQuery,window.SGAsearch,_,Backbone)