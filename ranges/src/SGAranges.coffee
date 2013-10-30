# # Full Text Search

window.SGAranges = {}

(($,SGAranges,_,Backbone) ->

  ## MODELS ##

  # Work
  class SGAranges.Work extends Backbone.Model
    defaults:
      "url"    : ""
      "id"     : ""
      "flat"   : false
      # "ranges" : new SGAranges.RangeList

  # Range
  class SGAranges.Range extends Backbone.Model
    defaults:
      "id"       : ""
      "label"    : ""
      "meta"     : ""
      # "canvases" : new SGAranges.CanvasList

  # Canvas
  class SGAranges.Canvas extends Backbone.Model
    defaults:
      "id"       : ""
      "label"    : ""
      "position" : 1
      "scUrl"    : ""
      "imgUrl"   : ""
      "status"   : {t: "grn", m: "grn"}

  ## COLLECTIONS ##

  # RangeList List
  class SGAranges.WorkList extends Backbone.Collection
    model: SGAranges.Work
    url: 'works.json' 

  # RangeList List
  class SGAranges.RangeList extends Backbone.Collection
    model: SGAranges.Range

  class SGAranges.CanvasList extends Backbone.Collection
    model: SGAranges.Canvas


  ## VIEWS ##

  # Work List View
  class SGAranges.WorkListView extends Backbone.View
    target: null

    render: (dest) ->
      @target = dest
      @collection.each @addOne, @
      @

    addOne: (model) =>
      view = new SGAranges.WorkView {model: model}
      $(@target).append view.render().$el

    clear: ->
      @collection.each (m) -> m.trigger('destroy')

  # Work view
  class SGAranges.WorkView extends Backbone.View
    template: _.template $('#work-template').html()
    initialize: ->
      @listenTo @model, 'change', @render
      @listenTo @model, 'destroy', @remove

    render: ->
      thisEl = @$el
      thisFlat = @model.attributes.flat
      thisTemplate = @template
      $.ajax
        url: @model.attributes.url
        type: 'GET'
        dataType: 'json'
        processData: false
        success: (data) -> SGAranges.processManifest data, thisFlat, thisEl, thisTemplate
      @

    remove: ->
      @$el.remove()
      @

  # Range List View
  class SGAranges.RangeListView extends Backbone.View
    target: null

    render: (dest) ->
      @target = dest
      @collection.each @addOne, @
      @

    addOne: (model) =>
      view = new SGAranges.RangeView {model: model}
      $(@target).append view.render().$el

    clear: ->
      @collection.each (m) -> m.trigger('destroy')

  # Range view
  class SGAranges.RangeView extends Backbone.View
    template: _.template $('#range-template').html()
    initialize: ->
      @listenTo @model, 'change', @render
      @listenTo @model, 'destroy', @remove

    render: ->
      @$el.html @template(@model.toJSON())
      @

    remove: ->
      @$el.remove()
      @

  # Canvas List View
  class SGAranges.CanvasListView extends Backbone.View
    target: null

    render: (dest) ->
      @target = dest
      @collection.each @addOne, @
      @

    addOne: (model) =>
      view = new SGAranges.CanvasView {model: model}
      $(@target).append view.render().$el

    clear: ->
      @collection.each (m) -> m.trigger('destroy')

  # Range view
  class SGAranges.CanvasView extends Backbone.View
    template: _.template $('#canvas-template').html()
    initialize: ->
      @listenTo @model, 'change', @render
      @listenTo @model, 'destroy', @remove

    render: ->
      @$el = @template(@model.toJSON())
      @

    remove: ->
      @$el.remove()
      @

  SGAranges.processCanvas = (canv, data, pos=null) =>
      canvas = canv["@id"]
      c = new SGAranges.Canvas()
      @clv.collection.add c

      # This might need to change when/if we'll have more than one sequence 
      # We only need to address the "canonical" sequence here, which we're assuming
      # is in first position.
      c_pos = if pos? then pos else $.inArray(canvas, data.sequences[0].canvases) + 1
      sc_url = data.service

      img_url = ""

      for i in data.images
        if i.on == canvas
          i_url = i.resource["@id"]                  
          resolver = i.resource.service["@id"]

          img_url = resolver + "?url_ver=Z39.88-2004&rft_id=" + i_url + "&svc_id=info:lanl-repo/svc/getRegion&svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000&svc.format=image/jpeg&svc.level=1"

      c_id = canv["@id"]
      canvas_safe_id = c_id.replace(/[:\/\.]/g, "_")

      c.set
        "id"       : canvas_safe_id
        "label"    : canv.label
        "position" : c_pos
        "scUrl"    : sc_url
        "imgUrl"   : img_url
        "status"   : {t: "grn", m: "grn"}

  SGAranges.processManifest = (data, flat, el, template) =>
      w_id = data["@id"]
      work_safe_id = w_id.replace(/[:\/\.]/g, "_")
 
      el.html template(
        "id"     : work_safe_id
        "title"  : if data.metadata.title? then data.metadata.title + " - " + data.label else data.label
        "meta"   : data.metadata
      )
    
      @rl = new SGAranges.RangeList()
      @rlv = new SGAranges.RangeListView collection: @rl

      for struct in data.structures

        r = new SGAranges.Range()
        @rlv.collection.add r

        s_id = struct["@id"]
        range_safe_id = s_id.replace(/[:\/\.]/g, "_")

        r.set
          "id"    : range_safe_id
          "label" : struct.label              

      if !flat then @rlv.render '#' + work_safe_id + ' .panel-body'

      if flat

        @cl = new SGAranges.CanvasList()
        @clv = new SGAranges.CanvasListView collection: @cl  

        for canv in data.canvases
          SGAranges.processCanvas canv, data

        @clv.render '#' + work_safe_id + ' .panel-body'

      else
        for struct in data.structures

          @cl = new SGAranges.CanvasList()
          @clv = new SGAranges.CanvasListView collection: @cl  

          s_id = struct["@id"]
          range_safe_id = s_id.replace(/[:\/\.]/g, "_")

          cur_pos = 0
          for canvas in struct.canvases
            cur_pos += 1
            for canv in data.canvases
              if canv["@id"] == canvas           
                SGAranges.processCanvas canv, data, cur_pos
                # This avoids rendering more than once
                # canvases that are included in multiple ranges
                break

          @clv.render '#' + range_safe_id + ' .row'



)(jQuery,window.SGAranges,_,Backbone)

# Work it, make it, do it, makes us
( ($) ->
  wl = new SGAranges.WorkList([
    id: "ox-frankenstein-notebook_a"
    url: "http://dev.shelleygodwinarchive.org/data/ox/ox-frankenstein-notebook_a/Manifest-index.jsonld"
    flat: true
  ,
    id: "ox-frankenstein-notebook_b"
    url: "http://dev.shelleygodwinarchive.org/data/ox/ox-frankenstein-notebook_b/Manifest-index.jsonld"
    flat: true
  ,
    id: "ox-frankenstein-notebook_c1"
    url: "http://dev.shelleygodwinarchive.org/data/ox/ox-frankenstein-notebook_c1/Manifest-index.jsonld"
    flat: true
  ,
    id: "ox-frankenstein-notebook_c2"
    url: "http://dev.shelleygodwinarchive.org/data/ox/ox-frankenstein-notebook_c2/Manifest-index.jsonld"
    flat: true
  ,
    id: "ox-frankenstein-volume_i"
    url: "http://dev.shelleygodwinarchive.org/data/ox/ox-frankenstein-volume_i/Manifest-index.jsonld"
    flat: false
  ,
    id: "ox-frankenstein-volume_ii"
    url: "http://dev.shelleygodwinarchive.org/data/ox/ox-frankenstein-volume_ii/Manifest-index.jsonld"
    flat: false
  ,
    id: "ox-frankenstein-volume_iii"
    url: "http://dev.shelleygodwinarchive.org/data/ox/ox-frankenstein-volume_iii/Manifest-index.jsonld"
    flat: false
  ])

  wlv = new SGAranges.WorkListView collection: wl
  wlv.render "#ranges_wrapper"
)(jQuery)

