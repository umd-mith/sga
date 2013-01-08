$ ->
  app = sga.application.top.initInstance $('#browser-container')
  sga.application.top.instance = app
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
      if app.getAuthenticated()
        item = app.dataStore.data.getItem app.getMetroParent()
        if item["cmd-plus"]?
          formId = item["cmd-plus"][0] + "-new-form"
          console.log "Showing", formId
          $('#'+formId).modal('show')

    $("#cmd-edit").click ->
      if app.getAuthenticated()
        item = app.dataStore.data.getItem app.getMetroParent()
        if item["cmd-edit"]?
          formId = item["cmd-edit"][0] + "-edit-form"
          console.log "Showing", formId
          $('#'+formId).modal('show')

    $("#cmd-off").click ->
      if app.getAuthenticated()
        window.location.href = "/oauth/logout"

    bits = window.location.href.split '#'
    if bits.length > 1
      if bits[1] == ""
        bits[1] = "top"
      app.setMetroParent bits[1]
    else
      app.setMetroParent "top"

    $("#li-trash").click ->
      if app.getAuthenticated()
        item = app.dataStore.data.getItem app.getMetroParent()
        if item.restType? and app.model(item.restType[0])?
          if confirm("Delete " + item.label[0] + "?")
            app.model(item.restType[0]).delete item.id, ->
              app.setMetroParent item.parent[0]

    app.events.onMetroParentChange.addListener (id) ->
      item = app.dataStore.data.getItem id
      console.log "changed to", item
      if item.restType? and app.model(item.restType[0])?
        app.model(item.restType[0]).inflateItem id

      if app.getAuthenticated()
        if item["cmd-edit"]?
          $("#li-edit").show()
        else
          $("#li-edit").hide()
        if item["cmd-plus"]?
          $("#li-plus").show()
        else
          $("#li-plus").hide()
      else
        $("#li-edit").hide()
        $("#li-plus").hide()

      # build breadcrumb
      crumbs = []
      tid = id
      while tid? and tid != "top"
        crumbs.push { id: tid, label: item.label[0] }
        tid = item.parent[0]
        item = app.dataStore.data.getItem tid
      $(".metro-breadcrumb").empty()
      if crumbs.length > 10
        crumbs = crumbs[0..9]
        $(".metro-breadcrumb").append($("<li>... <span class='divider'>/</span></li>"))
      if crumbs.length == 0
        $(".metro-breadcrumb").hide()
      else
        $(".metro-breadcrumb").show()

        crumbs.reverse()
       
        for crumb in crumbs
          if crumb.id == id
            li = $("<li class='active'></li>")
            li.text crumb.label
          else
            li = $("<li><a href='#'></a> <span class='divider'>/</span> </li>")
            li.find("a").text crumb.label
            ((c) -> li.find("a").click -> app.setMetroParent c)(crumb.id)
          $(".metro-breadcrumb").append(li)

    initCollection = (model, nom) ->
      app.model(model).getCollection (list) ->
        app.dataStore.data.updateItems [{
          id: "section-#{nom}"
          badge: list.length
        }]

    collections = []
    app.dataView.metroTopItems.events.onModelChange.addListener (dm, itemIds) ->
      for id in itemIds
        continue if id in collections
        item = dm.getItem id
        continue unless "SectionLink" in item.type
        continue unless item.id[0][0...8] == "section-"
        nom = item.id[0][8...item.id[0].length]
        model = item.model?[0]
        if nom? and nom != "" and model? and app.model(model)?
          collections.push id
          initCollection model, nom

    app.dataStore.data.loadItems [{
      id: "top"
      type: "SectionLink"
    }]

    sga.util.get
      url: '/'
      success: (data) ->
        items = []

        if data._embedded?
          count = 0
          for info in data._embedded
             count += 1
             key = info.id
             console.log "Loading", info
             if info._links?.self? && info.dataType? && !app.model(info.dataType)?
               app.addModel info.dataType, sga.model.initModel
                 collection_url: info._links.self
                 dataStore: app.dataStore.data
                 restType: info.dataType
                 parent: "section-#{key}"
                 schema: info.schema
                 application: -> app

             pi =
               id: "section-#{key}"
               type: 'SectionLink'
               rank: (if count == 1 then 2 else 1)
               parent: 'top'
               class: (if count == 1 then "primary" else "")
               order: 0
               badge: 0
               label: info.label
               model: info.dataType
             if key != "board"
               pi["cmd-plus"] = info.dataType
             items.push pi
        if data._links?
          for key, info of data._links
            if typeof info != "string"
              items.push
                id: "link-#{key}"
                parent: 'top'
                type: 'URLLink'
                link: info.url
                order: 10
                label: info.label
                class: (if info.dangerous then "danger" else "welcome")
        if data._text?
          for key, info of data._text
            if key == "top"
              parentId = key
            else
              items.push
                id: "text-#{key}"
                parent: info.parent || 'top'
                type: 'SectionLink'
                order: 5
                label: info.label
              parentId = "text-#{key}"
            if info._embedded?.sections?
              i = 0
              for s in info._embedded?.sections
                si =
                  id: "text-#{key}-section-#{i}"
                  parent: parentId
                  type: 'TextSection'
                  content: s.content
                  order: 1000
                  label: s.label
                if s.width?
                  si.width = s.width
                items.push si
                i += 1

        app.dataStore.data.loadItems items
        app.model("Manifest").addConfig
          inflateItem: (id) ->
            items = []
            items.push
              id: id
              "cmd-plus": "ManifestComponent"
            items
        app.model("Sequence").addConfig
          inflateItem: (id) ->
            items = []
            items.push
              id: id
              "cmd-plus": "SequenceComponent"
            items
        app.model("Image").addConfig
          inflateItem: (id) ->
            items = []
            items.push
              id: id
              "cmd-plus": "ImageAnnotation"
            items
