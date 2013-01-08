MITHGrid.globalNamespace "sga", (sga) ->
  sga.namespace "config", (config) ->
    config.url_base = '';

  sga.namespace "util", (util) ->
    util.ajax = (config) ->
      ops =
        url: sga.config.url_base + config.url
        type: config.type
        contentType: 'application/json'
        processData: false
        dataType: 'json'
        success: config.success
        error: config.error

      if config.data?
        ops.data = JSON.stringify config.data

      $.ajax ops

    util.get  = (config) -> util.ajax $.extend({ type: 'GET' },  config)
    util.post = (config) -> util.ajax $.extend({ type: 'POST' }, config)
    util.put  = (config) -> util.ajax $.extend({ type: 'PUT' },  config)
    util.delete  = (config) -> util.ajax $.extend({ type: 'DELETE' }, config)

    util.success_message = (msg) ->
      div = $("""
        <div class='alert alert-success'>
          <a class='close' data-dismiss='alert' href='#'>&times;</a>
          <h4 class='alert-heading'>Success!</h4>
        </div>
      """);
      div.append(msg);
      $("#messages").append(div);
      setTimeout ->
        div.animate {
          opacity: 0
        }, 1000, ->
          div.remove()
      , 2000

    util.error_message = (msg) ->
      div = $("""
        <div class='alert alert-error'>
          <a class='close' data-dismiss='alert' href='#'>&times;</a>
          <h4 class='alert-heading'>Uh oh!</h4>
        </div>
      """);
      div.append(msg);
      $("#messages").append(div);

  sga.namespace "model", (model) ->
    # we need a method to retrieve a collection and insert it into
    # the data store
    # we also need a way to create items and a way to respond to changes in
    # the data store
    model.initModel = (config) ->
      that = {}
      that.getCollection = (cb) ->
        sga.util.get
          url: config.collection_url
          success: (data) ->
            items = []
            for thing in data['_embedded']
              json = config.importItem thing
              json.restType = config.restType
              json.parent = config.parent
              items.push json
            config.dataStore.loadItems items
            if cb?
              cb(data['_embedded'])

      that.create = (data) ->
        json = config.exportItem data
        sga.util.post
          url: config.collection_url
          data: json
          success: (data) ->
            json = config.importItem data
            json.restType = config.restType
            json.parent = config.parent
            config.dataStore.loadItems [ json ]
            parentItem = config.dataStore.getItem config.parent
            config.dataStore.updateItems [{
              id: config.parent
              badge: parseInt(parentItem.badge[0],10) + 1
            }]

      that.delete = (id, cb) ->
        sga.util.delete
          url: config.collection_url + '/' + id
          success: ->
            config.dataStore.removeItems [ id ]
            # remove items for which this is the parent
            # this is based on the equivalent of !parent for this id
            objects = MITHGrid.Data.Set.initInstance
              values: id
            config.dataStore.removeItems config.dataStore.getSubjectsUnion(objects, "parent").items()
             
            parentItem = config.dataStore.getItem config.parent
            config.dataStore.updateItems [{
              id: config.parent
              badge: parseInt(parentItem.badge[0],10) - 1
            }]
            if cb?
              cb()

      that.update = (item) ->
        json = config.exportItem item
        sga.util.put
          url: config.collection_url + '/' + item.id
          data: json

      that.inflate = (id) -> config.inflateItem that, config.dataStore, id
      that.deflate = (id) -> config.deflateItem that, config.dataStore, id

      that

  sga.namespace "component", (component) ->
    component.namespace "modalForm", (modalForm) ->
      modalForm.initInstance = (args...) ->
        MITHGrid.initInstance 'sga.component.modalForm', args..., (that, container) ->
          options = that.options
          id = $(container).attr('id')
          $(container).modal('hide')
          $("#" + id + "-cancel").click ->
            $(container).modal('hide')
          $("#" + id + "-action").click ->
            data = {}
            $(container).find('.modal-form-input').each (idx, el) ->
              el = $(el)
              elId = el.attr('id')
              elId = elId.substr(id.length + 1)
              data[elId] = el.val()
              if not $.isArray(data[elId])
                data[elId] = [ data[elId] ]
            $(container).modal('hide')
            if options.model?.create?
              options.model.create data

          $(container).on 'show', ->
            $(container).find('.modal-form-input').val("")

  sga.namespace "presentation", (presentation) ->
    presentation.namespace "metroCtrl", (metroCtrl) ->
      metroCtrl.initInstance = (args...) ->
        MITHGrid.Presentation.initInstance 'sga.presentation.metroCtrl', args..., (that, container) ->
          options = that.options

    presentation.namespace "metroNav", (metroNav) ->
      metroNav.initInstance = (args...) ->
        MITHGrid.Presentation.initInstance 'sga.presentation.metroNav', args..., (that, container) ->
          options = that.options

          that.show = -> $(container).show()
          that.hide = -> $(container).hide()

          divider = $('<li class="divider"></li>')
          $(container).append(divider)

          home = $('<li></li>')
          homea = $('<a href="#" id="">Home</a>')
          home.append(homea)
          homea.click ->
            options.application().nextState
              parent: 'top'
              mode: 'List'

          divider.after(home)

          baseLens = (hubEl, presentation, model, itemId) ->
            rendering = {}

            item = model.getItem itemId

            el = $('<li></li>')
            rendering.el = el
            divider.before(el)

            a = $('<a href="#"></a>')
            el.append(a)
            rendering.a = a

            if item.title?
              a.text item.title[0]

            rendering.remove = ->
              el.remove()

            rendering.update = (item) ->
              if item.title?
                a.text item.title[0]
              else
                a.text ''

            rendering

          that.addLens 'URLLink', (hubEl, presentation, model, itemId) ->
            rendering = baseLens(hubEl, presentation, model, itemId)
            item = model.getItem itemId

            if item.link?
              link = item.link[0]
              $(rendering.a).click ->
                window.location.href = link

          that.addLens 'EmptyItem', baseLens

          that.addLens 'SectionLink', (hubEl, presentation, model, itemId) ->
            rendering = baseLens(hubEl, presentation, model, itemId)
            item = model.getItem itemId

            $(rendering.a).click -> 
              options.application().nextState
                parent: item.id[0]
                mode: 'List'

            rendering

          that.addLens 'ItemLink', (hubEl, presentation, model, itemId) ->
            rendering = baseLens(hubEl, presentation, model, itemId)
            item = model.getItem itemId
 
            $(rendering.a).click ->
              options.application().nextState
                parent: item.id[0]
                mode: 'Item'
              
          that.finishDisplayUpdate = ->

    presentation.namespace "metroItem", (metroItem) ->
      metroItem.initInstance = (args...) ->
        MITHGrid.Presentation.initInstance 'sga.presentation.metroItem', args..., (that, container) ->
          options = that.options
          that.show = -> $(container).show()
          that.hide = -> $(container).hide()
          header = $("<header class='subhead' id='overview'></header>")
          $(container).append(header)
          $(container).attr
            'data-spy': 'scroll'

          headerTitle = $("<h1></h1>")
          header.append(headerTitle)
          itemType = $("<p class='type'></p>")
          header.append(itemType)
          headerDescription = $("<p class='lead'></p>")
          header.append(headerDescription)
          subNav = $("<div class='subnav subnav-fixed'></div>")
          
          subNavList = $("<ul class='nav nav-pills'><li><a href='#overview'>Top</a></li></ul>")
          subNav.append(subNavList)
          header.append(subNav)

          subNav.scrollspy()

          options.application().events.onMetroParentChange.addListener (p) ->
            item = options.dataView.getItem p
            headerTitle.text item.title?[0]
            itemType.text item.restType?[0]
            headerDescription.text item.description?[0]

          that.finishDisplayUpdate = ->
            subNav.scrollspy('refresh')

          superRender = that.render

          that.render = (c, m, i) ->
            innerContainer = $("<section></section>")
            innerContainer.attr
              id: 'section-' + i

            rendering = superRender(innerContainer, m, i)

            return unless rendering?

            container.append(innerContainer)

            item = m.getItem i
            pageHeader = $("<div class='page-header'></div>")
            innerContainer.prepend(pageHeader)
            pageHeaderH1 = $("<h2></h2>")
            pageHeaderH1.text(item.title[0])
            pageHeader.append(pageHeaderH1)

            navItem = $("<li></li>")
            navItemA = $("<a></a>")
            navItemA.attr
              href: '#section-' + i
            navItemA.text(item.title[0])
            navItem.append(navItemA)
            subNavList.append(navItem)

            superUpdate = rendering.update
            rendering.update = (item) ->
              pageHeaderH1.text(item.title[0])
              navItemA.text(item.title[0])
              superUpdate(item)

            superRemove = rendering.remove
            rendering.remove = ->
              navItem.remove()
              superRemove()
              innerContainer.remove()

            rendering

          that.addLens 'SectionLink', (container, presentation, model, id) ->
            rendering = {}
            item = model.getItem id
            if item.parent?[0] == "top"
              return

            # we want to provide a presentation of items here, but these items
            # can't be used to bring up new content - they can only be
            # added/removed/rearranged (if order is important)
            # items can be selected
            container.append($("<p>Stuff goes here</p>"))
            rendering.update = (item) ->

            rendering.remove = ->

            rendering

    presentation.namespace "metro", (metro) ->
      metro.initInstance = (args...) ->
        MITHGrid.Presentation.initInstance 'sga.presentation.metro', args..., (that, container) ->
          options = that.options
          that.show = -> $(container).show()
          that.hide = -> $(container).hide()

          baseLens = (hubEl, presentation, model, itemId) ->
            rendering = {}

            item = model.getItem itemId

            el = $('<div></div>')
            rendering.el = el
            hubEl.append(el)
            badge = $('<span class="badge"></span>')
            el.append(badge)

            title = $('<h1></h1>')
            if item.title?
              title.text item.title[0]
            el.append title
            description = $('<p></p>');
            if item.description?
              description.text item.description[0]
            el.append description

            rendering.badge = badge
            rendering.description = description
            rendering.title = title

            if item.badge?
              badge.text item.badge[0]

            width = 2*(item.rank?[0] || 1)
            height = 2*(item.rank?[0] || 1)

            classes = ""
            if item.class?
              classes = item.class.join " "


            el.attr
              class: "tile width#{width} height#{height} #{classes}"

            finalHeight = el.height()
            finalWidth = el.width()
            el.height(0)
            el.width(0)

            el.animate {
              width: finalWidth
              height: finalHeight
            }, 200 * width, ->
              el.attr
                width: null
                height: null

            rendering.update = (item) -> 
              if item.description?
                description.text item.description[0]
              else
                description.text ''
              if item.title?
                title.text item.title[0]
              else
                title.text ''
              if item.badge?
                badge.text item.badge[0]
              else
                badge.text ''

            rendering.remove = ->
              el.animate {
                width: 0
                height: 0
                opacity: 0
              }, 200 * width, ->
                el.remove()

            rendering

          that.startDisplayUpdate = ->

          that.finishDisplayUpdate = ->
            $(container).masonry
              itemSelector: '.tile'
              columnWidth: 75

          that.addLens 'URLLink', (hubEl, presentation, model, itemId) ->
            rendering = baseLens(hubEl, presentation, model, itemId)
            item = model.getItem itemId

            if item.link?
              link = item.link[0]
              $(rendering.el).click ->
                window.location.href = link

          that.addLens 'EmptyItem', baseLens

          that.addLens 'SectionLink', (hubEl, presentation, model, itemId) ->
            rendering = baseLens(hubEl, presentation, model, itemId)
            item = model.getItem itemId

            $(rendering.el).click -> 
              options.application().nextState
                parent: item.id[0]

            rendering

          that.addLens 'ItemLink', (hubEl, presentation, model, itemId) ->
            rendering = baseLens(hubEl, presentation, model, itemId)
            item = model.getItem itemId
 
            $(rendering.a).click ->
              options.application().nextState
                parent: item.id[0]

  sga.namespace "application", (apps) ->
    apps.namespace "top", (top) ->
      top.initInstance = (args...) ->
        MITHGrid.Application.initInstance 'sga.application.top', args..., (that, container) ->
          that.pushState = ->
            window.History.pushState {
              parent: that.getMetroParent()
              mode: that.getMetroMode()
            }, '', '/'
          that.nextState = (opts) ->
            that.pushState()
            oldParent = that.getMetroParent()
            oldMode = that.getMetroMode()

            that.setMetroParent(opts.parent) if opts.parent?
            item = that.dataStore.data.getItem that.getMetroParent()
            if opts.mode?
              that.setMetroMode(opts.mode)
            else
              if item?.mode?
                that.setMetroMode(item.mode[0])
              else if item?.restType?
                that.setMetroMode('Item')
              else
                that.setMetroMode('List')

            newMode = that.getMetroMode()

            if oldMode == "Item" and newMode == "List" and item.parent == "top"
              # remove items to which oldParent pointed
              # this is based on the equivalent of !parent for this id
              oldItem = that.dataStore.data.getItem oldParent
              if oldItem.restType? and models[oldItem.restType?[0]]?
                models[oldItem.restType[0]].deflate oldParent
              else
                that.dataStore.data.removeItems that.dataStore.data.withParent(oldParent)

          models = {}

          that.addModel = (nom, model) -> models[nom] = model
          that.model = (nom) -> models[nom]

          that.dataStore.data.withParent = (p) ->
            objects = MITHGrid.Data.Set.initInstance
              values: oldParent
            that.dataStore.data.getSubjectsUnion(objects, "parent").items()
              
              

          that.ready ->
            that.events.onMetroParentChange.addListener (p) ->
              that.dataView.metroItems.setKey p
              item = that.dataStore.data.getItem p
              if item.title?
                $('#section-header').text item.title[0]
              if p == "top"
                $('#section-header').text "Home"
              if item.restType?
                $('#li-trash').show()
              else
                $('#li-trash').hide()

            that.events.onMetroModeChange.addListener (m) ->
              if m == "List"
                that.presentation.list.show()
                that.presentation.item.hide()
              else
                that.presentation.list.hide()
                that.presentation.item.show()

            that.setMetroMode("List")

            that.dataView.metroItems.events.onModelChange.addListener (model, itemIds) ->
              for id in itemIds
                item = model.getItem id
                if item.type and ("Command" in item.type)
                  liId = '#li-' + item.commandType[0]
                  if model.contains id
                    $(liId).show()
                  else
                    $(liId).hide()

MITHGrid.defaults 'sga.application.top',
  dataStores:
    data:
      types:
        HubItem: {}
        Project: {}
        Library: {}
        Board: {}
      properties: {}
  dataViews:
    metroItems:
      dataStore: 'data'
      type: MITHGrid.Data.SubSet
      key: 'top',
      expressions: [ '!parent' ]
    metroTopItems:
      dataStore: 'data'
      type: MITHGrid.Data.SubSet
      key: 'top',
      expressions: [ '!parent' ]
  variables:
    MetroParent:
      is: 'rw'
      default: 'top'
    MetroMode:
      is: 'rw'
      default: 'list'
  presentations:
    list:
      type: sga.presentation.metro
      container: " .sga-hub"
      dataView: 'metroItems'
    item:
      type: sga.presentation.metroItem
      container: " .sga-item"
      dataView: 'metroItems'
    nav:
      type: sga.presentation.metroNav
      container: " .sga-nav"
      dataView: 'metroTopItems'
  viewSetup: """
    <div class="navbar navbar-fixed-top">
     <div class="navbar-inner">
       <div class="container">
         <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
           <span class="icon-bar"></span>
           <span class="icon-bar"></span>
           <span class="icon-bar"></span>
         </a>
         <a class="brand" href="#" id="top-nav">Shared Canvas</a>
         <div class="nav-collapse">
           <ul class="nav">
             <li class="dropdown">
               <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                 <span id="section-header">Home</span>
                 <b class="caret"></b>
               </a>
              <ul class='dropdown-menu sga-nav'></ul>
             </li>
           </ul>
         </div>
       </div>
     </div>
    </div>
    <div class="row-fluid">
      <div class="span12 sga-hub"></div>
    </div>
    <div>
      <div class="span12 sga-item" data-spy='scroll' data-target='.subnav' data-offset='60'></div>
    </div>
    <div class="navbar navbar-fixed-bottom">
      <div class="navbar-inner">
        <div class="container">
          <ul class="nav pull-right" id="right-commands">
            <li class="divider-vertical"></li>
            <li id="li-trash" style="display: none;"><a href="#" id="cmd-trash"><i class="icon-trash icon-white"></i></a></li>
            <li id="li-remove" style="display: none;"><a href="#" id="cmd-remove"><i class="icon-remove icon-white"></i></a></li>
            <li id="li-plus" style="display: none;"><a href="#" id="cmd-plus"><i class="icon-plus icon-white"></i></a></li>
          </ul>
          <ul class="nav pull-left">
            <li id="li-home"><a href="#" id="cmd-home"><i class="icon-home icon-white"></i></a></li>
          </ul>
        </div>
      </div>
    </div>
  """

$ ->
  app = sga.application.top.initInstance $('#browser-container')
  app.run()

  app.ready ->
    $("#top-nav").click ->
      app.nextState
        parent: 'top'
        mode: 'List'
    $("#cmd-home").click ->
      app.nextState
        parent: 'top'
        mode: 'List'

    $("#cmd-plus").click ->
      formId = app.getMetroParent() + "-new-form"
      $('#'+formId).modal('show')

    bits = window.location.href.split '#'
    if bits.length > 1
      if bits[1] == ""
        bits[1] = "top"
      app.setMetroParent bits[1]
    else
      app.setMetroParent "top"

    app.dataStore.data.loadItems [{
      id: 'section-manifests'
      type: 'SectionLink'
      rank: 2
      class: 'primary'
      parent: 'top'
      badge: 0
      title: 'Manifests'
    }, {
      id: 'section-canvases'
      type: 'SectionLink'
      rank: 1
      parent: 'top'
      badge: 0
      title: 'Canvases'
    }, {
      id: 'section-layers'
      type: 'SectionLink'
      rank: 1
      parent: 'top'
      badge: 0
      title: 'Layers'
    }, {
      id: 'section-annotation-lists'
      type: 'SectionLink'
      rank: 1
      parent: 'top'
      badge: 0
      title: 'Annotation Lists'
    }, {
      id: 'section-sequences'
      type: 'SectionLink'
      rank: 1
      parent: 'top'
      badge: 0
      title: 'Sequences'
    }, {
      id: 'section-ranges'
      type: 'SectionLink'
      rank: 1
      parent: 'top'
      badge: 0
      title: 'Ranges'
    }, {
       id: 'section-images'
       type: 'SectionLink'
       rank: 1
       parent: 'top'
       badge: 0
       title: 'Images'
    }, {
       id: 'section-image-annotation-lists'
       type: 'SectionLink'
       rank: 1
       parent: 'top'
       badge: 0
       title: 'Image Lists'
    }]

    $("#li-trash").click ->
      item = app.dataStore.data.getItem app.getMetroParent()
      if item.restType? and app.model(item.restType[0])?
        if confirm("Delete " + item.title[0] + "?")
          app.model(item.restType[0]).delete item.id, ->
            app.setMetroParent item.parent[0]

    app.addModel 'Manifest', sga.model.initModel
      collection_url: '/manifest'
      dataStore: app.dataStore.data
      restType: 'Manifest'
      parent: 'section-manifests'
      importItem: (data) ->
        id: data.uuid
        type: 'SectionLink'
        title: data.label
      exportItem: (data) ->
        label: data.title[0]
      inflateItem: (restModel, dataStore, id) ->
        # we want to make intermediate objects for each of the things
        # a manifest can have
        parent = dataStore.getItem id
        items = []
        items.push
          id: "#{id}-sequences"
          type: 'SectionLink'
          title: 'Sequences'
          parent: id

        if parent.sequences?
          for i in parent.sequences
            seq = dataStore.getItem i
            items.push
              id: "#{id}-sequence-#{i}"
              type: 'ItemLink'
              title: seq.title
              parent: id
              linksTo: i

        items.push
          id: "#{id}-layers"
          type: 'SectionLink'
          title: 'Layers'
          parent: id

        if parent.layers?
          for i in parent.layers
            layer = dataStore.getItem i
            items.push
              id: "#{id}-layer-#{i}"
              type: 'ItemLink'
              title: layer.title
              parent: id
              linksTo: i

        dataStore.loadItems items

      deflateItem: (restModel, dataStore, id) ->
        # we want to go two levels down
        ids = dataStore.withParent(id)
        for i in ids
          dataStore.removeItems dataStore.withParent(i)
        dataStore.removeItems ids
        
    app.addModel 'Sequence', sga.model.initModel
      collection_url: '/sequence'
      dataStore: app.dataStore.data
      restType: 'Sequence'
      parent: 'section-sequences'
      importItem: (data) ->
        id: data.uuid
        type: 'SectionLink'
        title: data.label
      exportItem: (data) ->
        label: data.title[0]
      inflateItem: (restModel, dataStore, id) ->
      deflateItem: (restModel, dataStore, id) ->
        # we want to go two levels down
        ids = dataStore.withParent(id)
        for i in ids
          dataStore.removeItems dataStore.withParent(i)
        dataStore.removeItems ids

    app.addModel 'Canvas', sga.model.initModel
      collection_url: '/canvas'
      dataStore: app.dataStore.data
      restType: 'Canvas'
      parent: 'section-canvases'
      importItem: (data) ->
        id: data.uuid
        type: 'SectionLink'
        title: data.label
      exportItem: (data) ->
        label: data.title[0]
      inflateItem: (restModel, dataStore, id) ->

      deflateItem: (restModel, dataStore, id) ->
        # we want to go two levels down
        ids = dataStore.withParent(id)
        for i in ids
          dataStore.removeItems dataStore.withParent(i)
        dataStore.removeItems ids

    app.model('Manifest').getCollection (list) ->
      app.dataStore.data.loadItems [{
        id: 'section-manifests-new'
        parent: 'section-manifests'
        type: 'Command'
        commandType: 'plus'
      }]

      app.dataStore.data.updateItems [{
        id: 'section-manifests'
        badge: list.length
      }]

    app.model('Sequence').getCollection (list) ->
      app.dataStore.data.loadItems [{
        id: 'section-sequences-new'
        parent: 'section-sequences'
        type: 'Command'
        commandType: 'plus'
      }]

      app.dataStore.data.updateItems [{
        id: 'section-sequences'
        badge: list.length
      }]

    app.model('Canvas').getCollection (list) ->
      app.dataStore.data.loadItems [{
        id: 'section-canvases-new'
        parent: 'section-canvases'
        type: 'Command'
        commandType: 'plus'
      }]

      app.dataStore.data.updateItems [{
        id: 'section-canvases'
        badge: list.length
      }]

    sga.component.modalForm.initInstance $("#section-manifests-new-form"),
      application: -> app
      model: app.model('Manifest')
    sga.component.modalForm.initInstance $("#section-sequences-new-form"),
      application: -> app
      model: app.model('Sequence')
    sga.component.modalForm.initInstance $("#section-canvases-new-form"),
      application: -> app
      model: app.model('Canvas')

    app.events.onMetroParentChange.addListener (id) ->
      item = app.dataStore.data.getItem id
      if item.restType? and app.model(item.restType[0])?
        app.model(item.restType[0]).inflate id
