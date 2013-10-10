# # Full Text Search

window.SGAranges = {}

(($,SGAranges,_,Backbone) ->

  ## MODELS ##

  # Work
  class SGAranges.Work extends Backbone.Model
    defaults:
      "id"     : ""
      "title"  : "[Title]"
      "meta"   : "[Work Metadata]"
      # "ranges" : new SGAranges.RangeList

  # Range
  class SGAranges.Range extends Backbone.Model
    defaults:
      "id"       : ""
      "label"    : "[Range Label]"
      "meta"     : "[Range Metadata]"
      # "canvases" : new SGAranges.CanvasList

  # Canvas
  class SGAranges.Canvas extends Backbone.Model
    defaults:
      "id"       : ""
      "label"    : "[Canvas Label]"
      "position" : 1
      "scUrl"    : ""
      "imgUrl"   : ""
      "status"   : {t: "red", m: "red"}

  ## COLLECTIONS ##

  # RangeList List
  class SGAranges.WorkList extends Backbone.Collection
    model: SGAranges.Work

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
      @$el.html @template(@model.toJSON())
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

  SGAranges.LoadRanges = (manifest) ->

    processManifest = (data) =>

      @wl = new SGAranges.WorkList()
      @wlv = new SGAranges.WorkListView collection: @wl

      w = new SGAranges.Work()
      @wlv.collection.add w

      w_id = data["@id"]
      work_safe_id = w_id.replace(/[:\/\.]/g, "_")

      w.set
        "id"     : work_safe_id
        "title"  : data.label
        "meta"   : data.metadata

      @wlv.render "#ranges_wrapper"
    
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

      @rlv.render '#' + work_safe_id + ' .panel-body'

      for struct in data.structures

        @cl = new SGAranges.CanvasList()
        @clv = new SGAranges.CanvasListView collection: @cl  

        s_id = struct["@id"]
        range_safe_id = s_id.replace(/[:\/\.]/g, "_")

        for canvas in struct.canvases
          for canv in data.canvases
            if canv["@id"] == canvas
              c = new SGAranges.Canvas()
              @clv.collection.add c

              # This might need to change when/if we'll have more than one sequence 
              # We only need to address the "canonical" sequence here, which we're assuming
              # is in first position.
              c_pos = $.inArray(canvas, data.sequences[0].canvases) + 1

              sc_url = "/sc/" + work_safe_id

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
                "status"   : {t: "red", m: "red"}

        @clv.render '#' + range_safe_id + ' .row'

    $.ajax
      url: manifest
      type: 'GET'
      dataType: 'json'
      processData: false
      success: processManifest

  #############
  #############

  SGAranges.LoadCanvasesOnly = (manifest) ->

    processManifest = (data) =>

      @wl = new SGAranges.WorkList()
      @wlv = new SGAranges.WorkListView collection: @wl

      w = new SGAranges.Work()
      @wlv.collection.add w

      w_id = data["@id"]
      work_safe_id = w_id.replace(/[:\/\.]/g, "_")

      w.set
        "id"     : work_safe_id
        "title"  : data.label
        "meta"   : data.metadata

      @wlv.render "#ranges_wrapper"

      @cl = new SGAranges.CanvasList()
      @clv = new SGAranges.CanvasListView collection: @cl  

      for canv in data.canvases
        canvas = canv["@id"]
        c = new SGAranges.Canvas()
        @clv.collection.add c

        # This might need to change when/if we'll have more than one sequence 
        # We only need to address the "canonical" sequence here, which we're assuming
        # is in first position.
        c_pos = $.inArray(canvas, data.sequences[0].canvases) + 1

        sc_url = "/sc/" + work_safe_id

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
          "status"   : {t: "red", m: "red"}
      @clv.render '#' + work_safe_id + ' .panel-body'

    $.ajax
      url: manifest
      type: 'GET'
      dataType: 'json'
      processData: false
      success: processManifest

)(jQuery,window.SGAranges,_,Backbone)

# Work it, make it, do it, makes us
( ($) ->

  # SGAranges.LoadCanvasesOnly "ranges-sample.json"
  # SGAranges.LoadRanges "ranges-sample.json"
  SGAranges.LoadCanvasesOnly "Manifest.jsonld"
  # SGAranges.LoadRanges "Manifest.jsonld"

)(jQuery)