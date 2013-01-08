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
      makeSubstitutions = (template, data) ->
        orig = template
        if template.indexOf("{?") >= 0
          bits = template.split('{?')
          for i in [0...bits.length]
            if i % 2 == 1
              mbs = bits[i].split("}")
              bits[i] = (data[mbs[0]]||'') + mbs[1]
          template = bits.join("")
        template
  
      that.getCollection = (info, cb) ->
        if $.isFunction(info)
          cb = info
          info = {}
  
        url = makeSubstitutions config.collection_url, info
        parent = makeSubstitutions config.parent, info
  
        sga.util.get
          url: url
          success: (data) ->
            items = []
            for thing in data._embedded
              json = that.importItem thing
              json.parent = parent
              if !json.id? and config.buildId?
                json.id = config.buildId json
              items.push json
            console.log url, items
            config.dataStore.loadItems items
            if cb?
              cb(data._embedded)
  
      that.render = (container, presentation, model, id) ->
        rendering = {}
        # each of the things we belong to get rendered as 2x2 boxes
        if config?.schema?
          if config.schema.belongs_to?
            for k, v of config.schema.belongs_to
              console.log k
  
        rendering.update = (item) ->
  
        rendering.remove = ->
          $(container).empty()
  
        rendering
  
      that.importItem = (data) ->
        # use the config.schema to map data
        json = {}
        if config?.schema?
          if config.schema.properties?
            for k, v of config.schema.properties
              json[v.source || k] = data[k]
          if config.schema.embedded?
            for k, v of config.schema.embedded
              if data._embedded?[k]?
                json[k] = []
                for ei in data._embedded[k]
                  if $.isPlainObject(ei)
                    ei = ei._links?.self
                  if ei?
                    bits = ei.split("/")
                    if bits?.length
                      json[k].push bits[bits.length-1]
  
          if config.schema.belongs_to?
            # make sure we have each thing linked in
            for k, v of config.schema.belongs_to
              bits = data._links?[k]?.split("/")
              if bits?.length
                id = bits[bits.length-1]
                if id?
                  json[v.source || k] = id
                  if v.valueType? && config.application().model(v.valueType)?
                    config.application().model(v.valueType).load(id)
                      
        json.type = config.itemType || 'SectionLink'
        json.restType = config.restType
        json
  
      that.exportItem = (data) ->
        json = {}
        console.log "exportItem", data
        for k, v of config?.schema?.properties
          if v.is == "rw" and v.valueType != "hash"
            if data[v.source]?.length == 1
              json[k] = data[v.source][0]
            else if data[v.source]?.length > 1
              json[k] = data[v.source]
            else if data[v.source]? and data[v.source].length == 0
              json[k] = null
        console.log "schema:", config.schema
        console.log "exporting", data
        for k, v of config?.schema?.embedded
          if v.is != "ro" and v.valueType != "hash"
            if data[k]?
              json._embedded = json._embedded || {}
              json._embedded[k] = data[k]
        json
  
      that.schema = -> config.schema
  
      that.addConfig = (c) ->
        config = $.extend(config, true, c)
  
      that.inflateItem = (id) ->
        # we want to add links to various things
        # for each item in belongs_to, we have a linking item
        item = config.dataStore.getItem id
        items = []
        items.push $.extend {}, true, item, {
          id: "#{id}-factsheet"
          type: "FactSheet"
          parent: id
        }
  
        if config?.inflateItem?
          items = items.concat config.inflateItem(id)
        parents = MITHGrid.Data.Set.initInstance [ id ]
        newParents = parents
        newSize = parents.size()
        oldSize = 0
        while oldSize != newSize
          newParents = config.dataStore.getObjectsUnion(newParents, "parent")
          parents.add(x) for x in newParents.items()
          oldSize = newSize
          newSize = parents.size()
        
        if config?.schema?
          if config.schema.belongs_to?
            for k, v of config.schema.belongs_to
              if item[v.source || k]?
                for i in item[v.source || k]
                  # if i is in the chain above us, then don't add it here
                  if !parents.contains(i)
                    linkedItem = config.dataStore.getItem i
                    if linkedItem?.restType?
                      title = linkedItem.restType[0]
                    else
                      title = v.source || l
                    items.push
                      id: "#{id}-#{i}-link"
                      type: "ItemLink"
                      label: title
                      parent: id
                      link: i
          if config.schema.embedded?
            for k, v of config.schema.embedded
              if item[k]?
                for i in item[k]
                  linkedItem = config.dataStore.getItem i
                  if linkedItem?.label?
                    title = linkedItem.label[0]
                  else
                    title = "#{k} #{i}"
                  items.push
                    id: "#{id}-#{i}-#{k}-link"
                    type: "ItemLink"
                    label: title
                    parent: id
                    link: i
                 
        console.log "Inflated #{id}", items
        for item in items
          oldItem = config.dataStore.getItem item.id
          if oldItem.type?
            console.log "update", item
            config.dataStore.updateItems [ item ]
          else
            console.log "load", item
            config.dataStore.loadItems [ item ]
  
      that.deflateItem = (id) ->
        objects = MITHGrid.Data.Set.initInstance [ id ]
        objects = config.dataStore.getSubjectsUnion(objects, "parent")
        while objects.size() > 0
          config.dataStore.removeItems objects.items()
          objects = config.dataStore.getSubjectsUnion(objects, "parent")
  
      that.load = (info, id) ->
        if !id?
          id = info
          info = {}
        url = makeSubstitutions config.collection_url, info
        sga.util.get
          url: url + '/' + id
          success: (data) ->
            json = that.importItem data
            json.restType = config.restType
            json.parent = config.parent
            if !json.id? and config.buildId?
              json.id = config.buildId json
            if config.dataStore.contains(id)
              config.dataStore.updateItems [ json ], ->
                list = config.dataStore.withParent(config.parent)
                count = list.length
                config.dataStore.updateItems [{
                  id: config.parent
                  badge: count
                }]
            else
              config.dataStore.loadItems [ json ], ->
                list = config.dataStore.withParent(config.parent)
                count = list.length
                config.dataStore.updateItems [{
                  id: config.parent
                  badge: count
                }]
  
      that.create = (data) ->
        url = makeSubstitutions config.collection_url, data
        json = that.exportItem data
        sga.util.post
          url: url
          data: json
          success: (data) ->
            json = that.importItem data
            json.restType = config.restType
            json.parent = config.parent
            if !json.id and config.buildId?
              json.id = config.buildId json
            config.dataStore.loadItems [ json ]
            parentItem = config.dataStore.getItem config.parent
            config.dataStore.updateItems [{
              id: config.parent
              badge: parseInt(parentItem.badge[0],10) + 1
            }]
  
      that.delete = (info, id, cb) ->
        if $.isFunction(id)
          cb = id
          id = info
          info = {}
        url = makeSubstitutions config.collection_url, info
        sga.util.delete
          url: url + '/' + id
          success: ->
            that.deflateItem id
            config.dataStore.removeItems [ id ]
             
            parentItem = config.dataStore.getItem config.parent
            config.dataStore.updateItems [{
              id: config.parent
              badge: parseInt(parentItem.badge[0],10) - 1
            }]
            if cb?
              cb()
  
      that.update = (item, cb) ->
        json = that.exportItem item
        url = makeSubstitutions config.collection_url, item
        sga.util.put
          url: url + '/' + item.id
          data: json
          success: (data) ->
            json = that.importItem data
            json.restType = config.restType
            if !json.id and config.buildId?
              json.id = config.buildId json
            config.dataStore.updateItems [ json ]
            cb(json)
          error: -> cb()
      that

  sga.namespace "component", (component) ->
    component.namespace "modalForm", (modalForm) ->
      modalForm.initInstance = (args...) ->
        MITHGrid.initInstance 'sga.component.modalForm', args..., (that, container) ->
          options = that.options
          id = $(container).attr('id')
          $(container).modal({ keyboard: true, show: false })
          $("##{id}-cancel").click -> $(container).modal('hide')
          $("##{id}-action").click ->
            that.events.onAction.fire()
  
    component.namespace "newItemForm", (modalForm) ->
      modalForm.initInstance = (args...) ->
        component.modalForm.initInstance 'sga.component.newItemForm', args..., (that, container) ->
          options = that.options
          id = $(container).attr('id')
          that.events.onAction.addListener ->
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
  
    component.namespace "editItemForm", (modalForm) ->
      modalForm.initInstance = (args...) ->
        component.modalForm.initInstance 'sga.component.editItemForm', args..., (that, container) ->
          options = that.options
          id = $(container).attr('id')
          that.events.onAction.addListener ->
            data = {}
            $(container).find('.modal-form-input').each (idx, el) ->
              el = $(el)
              elId = el.attr('id')
              elId = elId.substr(id.length+1)
              data[elId] = el.val()
              if not $.isArray(data[elId])
                data[elId] = [ data[elId] ]
            $(container).modal('hide')
            data.id = options.application().getMetroParent()
            if options.update?
              options.update data
  
          $(container).on 'show', ->
            app = options.application()
            item = app.dataStore.data.getItem app.getMetroParent()
            $(container).find('.modal-form-input').each (idx, el) ->
              el = $(el)
              elId = el.attr('id')
              elId = elId.substr(id.length+1)
              el.val(item[elId]?[0] || "")
  
            if options.initForm?
              options.initForm container
  
    # used to tie another item to this one
    component.namespace "addItemForm", (modalForm) ->
      modalForm.initInstance = (args...) ->
        component.modalForm.initInstance 'sga.component.addItemForm', args..., (that, container) ->
          options = that.options
          id = $(container).attr('id')
          itemOptions = null
          typeOptions = null
          that.events.onAction.addListener ->
            $(container).modal('hide')
            app = options.application()
            if typeOptions? and itemOptions?
              itemType = typeOptions.val()
              targetId = itemOptions.val()
              target = app.dataStore.data.getItem targetId
              sourceId = app.getMetroParent()
              source = app.dataStore.data.getItem sourceId
              console.log "Source:", source
              console.log "Connect", itemType, targetId, "to", app.getMetroParent()
              list = source[itemType] || []
              list.push targetId
              changes = { id: source.id }
              changes[itemType] = list
              app.model(source.restType[0]).update changes, (json) ->
                if !json?
                  # error
                else
                  item =
                    id: "#{sourceId}-#{targetId}-link"
                    label: target.label
                    type: 'ItemLink'
                    parent: sourceId
                    link: targetId
                  console.log "Adding", item
                  app.dataStore.data.loadItems [ item ]
   
          $(container).on 'show', ->
            app = options.application()
            form = $(container).find('form')
            form.empty()
            typeSelect = $ """
              <label>Item Type</label>
            """
            form.append(typeSelect)
            typeOptions = $(" <select></select> ")
            typeOptions.attr
              id: "#{id}-type"
            form.append(typeOptions)
            # add an option for each type
            # as stated in the schema (embedded types)
            schema = options.model.schema()
            for thing, info of schema.embedded
              console.log "embedded:", thing, info
              item = app.dataStore.data.getItem "section-#{thing}"
              console.log "section-#{thing}:", item
              if item.label?
                option = $("<option></option>")
                option.text item.label[0]
                option.attr
                  value: thing
                typeOptions.append(option)
  
            itemSelect = $("<label>Item</label>")
            itemOptions = $("<select></select>")
            itemOptions.attr
              id: "#{id}-item"
            form.append(itemSelect)
            form.append(itemOptions)
            updateItemOptions = ->
              type = typeOptions.val()
              itemOptions.empty()
              ids = app.dataStore.data.withParent "section-#{type}"
              for id in ids
                oitem = app.dataStore.data.getItem id
                if oitem.label? and oitem.id?
                  option = $("<option></option>")
                  option.text oitem.label[0]
                  option.attr
                    value: oitem.id[0]
                  itemOptions.append(option)
            updateItemOptions()
            typeOptions.change updateItemOptions
  
    # used to create an annotation tying another item to this one
    component.namespace "addAnnotationForm", (modalForm) ->
      modalForm.initInstance = (args...) ->
        component.modalForm.initInstance 'sga.component.addAnnotationForm', args..., (that, container) ->
          options = that.options
          # options.annotationTypes should have a list of annotation types
          # options.annotationModel should be the model to use
          id = $(container).attr('id')
          annoOptions = null
          itemOptions = null
          typeOptions = null
          that.events.onAction.addListener ->
            $(container).modal('hide')
            app = options.application()
            if annoOptions? and typeOptions? and itemOptions?
              annoType = annoOptions.val()
              itemType = typeOptions.val()
              targetId = itemOptions.val()
              target = app.dataStore.data.getItem targetId
              sourceId = app.getMetroParent()
              source = app.dataStore.data.getItem sourceId
              console.log "Source:", source
              console.log "Connect", itemType, targetId, "to", app.getMetroParent()
              console.log {
                annoType: annoType
                itemType: itemType
                targetId: targetId
              }
              console.log "Use model #{annoType} to create a new item:"
              newItem = { }
              newItem[itemType] = [ targetId ]
              # we need to add metroparentid
              newItem[options.parentProperty] = [ app.getMetroParent() ]
              id = $(container).attr 'id'
              $(container).find('.modal-form-input').each (idx, el) ->
                el = $(el)
                elId = el.attr('id')
                elId = elId.substr(id.length + 1)
                newItem[elId] = el.val()
                if not $.isArray(newItem[elId])
                  newItem[elId] = [ newItem[elId] ]
              console.log newItem
                
              # this is where we need to make this an annotation
              app.model(annoType).create newItem, (json) ->
                console.log "Got back:", json
                if !json?
                  # error
                else
                  item =
                    id: "#{sourceId}-#{targetId}-link"
                    label: target.label
                    type: 'ItemLink'
                    parent: sourceId
                    link: targetId
                  console.log "Adding", item
                  app.dataStore.data.loadItems [ item ]
  
          form = $(container).find('form')
          annoSelect = $ """
            <label>Annotation Type</label>
          """
          form.append(annoSelect)
          annoOptions = $(" <select></select> ")
          annoOptions.attr
            id: "#{id}-type"
          form.append(annoOptions)
  
          typeSelect = $ """
            <label>Target Type</label>
          """
          form.append(typeSelect)
          typeOptions = $(" <select></select> ")
          typeOptions.attr
            id: "#{id}-target"
          form.append(typeOptions)
  
          itemSelect = $("<label>Item</label>")
          itemOptions = $("<select></select>")
          itemOptions.attr
            id: "#{id}-item"
          form.append(itemSelect)
          form.append(itemOptions)
   
          $(container).on 'show', ->
            # here, we use the things embedded in the thing embedded here
            app = options.application()
  
            $(container).find('.modal-form-input').each (idx, el) ->
              $(el).val("")
  
            for t in options.annotationTypes
              item = app.dataStore.data.getItem "section-#{t}"
              console.log item
              if item.label? and item.model?
                option = $("<option></option>")
                option.text item.label[0]
                option.attr
                  value: item.model[0]
                annoOptions.append(option)
  
  
            updateTypeOptions = ->
              # add an option for each type
              # as stated in the schema (embedded types)
              typeOptions.empty()
              annoType = annoOptions.val()
              console.log "annoType", annoType
              return unless annoType?
              schema = app.model(annoType)?.schema()
              console.log "Schema:", schema
              return unless schema?.embedded?
              for thing, info of schema.embedded
                console.log "embedded:", thing, info
                item = app.dataStore.data.getItem "section-#{thing}"
                console.log "section-#{thing}:", item
                if item.label?
                  option = $("<option></option>")
                  option.text item.label[0]
                  option.attr
                    value: thing
                  typeOptions.append(option)
  
  
            updateItemOptions = ->
              type = typeOptions.val()
              itemOptions.empty()
              ids = app.dataStore.data.withParent "section-#{type}"
              for id in ids
                oitem = app.dataStore.data.getItem id
                if oitem.label? and oitem.id?
                  option = $("<option></option>")
                  option.text oitem.label[0]
                  option.attr
                    value: oitem.id[0]
                  itemOptions.append(option)
  
            updateTypeOptions()
            updateItemOptions()
  
            annoOptions.change updateTypeOptions
            typeOptions.change updateItemOptions

  sga.namespace "presentation", (presentation) ->
    # provides an ordered set of items - things can be reordered by clicking
    # and dragging -- things can be added as well
    presentation.namespace "metroSet", (metroSet) ->
      metroSet.initInstance = (args...) ->
        MITHGrid.Presentation.initInstance 'sga.presentation.metroSet', args..., (that, container) ->
          
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
  
          superRender = that.render
  
          orderedRenderings = [ ]
  
          that.render = (c, m, i) ->
            cdiv = $('<li></li>')
            rendering = superRender(cdiv, m, i)
            return unless rendering?
  
            rendering.container = cdiv
  
            # now we want to add them in order
            if !rendering.order?
              divider.before(cdiv)
            else
              if orderedRenderings.length == 0
                $(container).prepend(cdiv)
                orderedRenderings.push rendering
              else
                if orderedRenderings[0].order > rendering.order
                  $(container).prepend(cdiv)
                  orderedRenderings.unshift rendering
                else if orderedRenderings[orderedRenderings.length-1].order <= rendering.order   
                  orderedRenderings[orderedRenderings.length-1].container.after(cdiv)
                  orderedRenderings.push rendering
                else # it's somewhere in the middle
                  for i in [0...orderedRenderings.length]
                    if orderedRenderings[i].order > rendering.order
                      orderedRenderings[i].container.before(cdiv)
                      orderedRenderings.splice i, 0, rendering
                      break
            rendering
  
  
          baseLens = (el, presentation, model, itemId) ->
            rendering = {}
  
            item = model.getItem itemId
  
            rendering.order = item.order?[0]
  
            #el = $('<li></li>')
            rendering.el = el
            #divider.before(el)
  
            a = $('<a href="#"></a>')
            el.append(a)
            rendering.a = a
  
            if item.label?
              a.text item.label[0]
  
            rendering.remove = ->
              el.remove()
  
            rendering.update = (item) ->
              if item.label?
                a.text item.label[0]
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
  
    presentation.namespace "metro", (metro) ->
      metro.initInstance = (args...) ->
        MITHGrid.Presentation.initInstance 'sga.presentation.metro', args..., (that, container) ->
          options = that.options
          that.show = -> $(container).show()
          that.hide = -> $(container).hide()
  
          superRender = that.render
  
          orderedRenderings = [ ]
  
          that.render = (c, m, i) ->
            cdiv = $('<div></div>')
            rendering = superRender(cdiv, m, i)
            return unless rendering?
  
            rendering.container = cdiv
  
            # now we want to add them in order
            if !rendering.order?
              $(container).append(cdiv)
            else
              if orderedRenderings.length == 0
                $(container).prepend(cdiv)
                orderedRenderings.push rendering
              else
                if orderedRenderings[0].order > rendering.order
                  container.prepend(cdiv)
                  orderedRenderings.unshift rendering
                else if orderedRenderings[orderedRenderings.length-1].order <= rendering.order
                  orderedRenderings[orderedRenderings.length-1].container.after(cdiv)
                  orderedRenderings.push rendering
                else # it's somewhere in the middle
                  for i in [0...orderedRenderings.length]
                    if orderedRenderings[i].order > rendering.order
                      orderedRenderings[i].container.before(cdiv)
                      orderedRenderings.splice i, 0, rendering
                      break
  
            finalHeight = cdiv.height()
            finalWidth = cdiv.width()
  
            # first animate to a box, then to a rectangle as needed
            cdiv.height(0)
            cdiv.width(0)
            if finalWidth < finalHeight
              cdiv.animate {
                width: finalWidth
                height: finalWidth
              }, finalWidth, ->
                cdiv.removeAttr('width')
                cdiv.removeAttr('height')
              cdiv.animate {
                height: finalHeight
              }, (finalHeight - finalWidth), ->
                cdiv.removeAttr('height')
                cdiv.removeAttr('width')
            else if finalWidth > finalHeight
              cdiv.animate {
                width: finalHeight
                height: finalHeight
              }, finalHeight, ->
                cdiv.removeAttr('height')
                cdiv.removeAttr('width')
              cdiv.animate {
                width: finalWidth
              }, (finalWidth - finalHeight), ->
                cdiv.removeAttr('height')
                cdiv.removeAttr('width')
            else
              cdiv.animate {
                height: finalHeight
                width: finalWidth
              }, finalWidth, ->
                cdiv.removeAttr('height')
                cdiv.removeAttr('width')
  
            superRemove = rendering.remove
            rendering.remove = ->
              cdiv.animate {
                width: 0
                height: 0
                opacity: 0
              }, (if finalWidth > finalHeight then finalHeight else finalWidth)*2, ->
                cdiv.remove()
              i = rendering in orderedRenderings
              if i >= 0
                orderedRenderings.splice i, 1
              superRemove() if superRemove?
            
            rendering
  
          baseLens = (el, presentation, model, itemId) ->
            rendering = {}
  
            item = model.getItem itemId
  
            if item.order?
              rendering.order = item.order[0]
  
            rendering.el = el
  
            badge = $('<div class="badge"></div>')
            if item.badge?
              badge.text item.badge[0]
            el.append(badge)
  
            title = $('<h1></h1>')
            if item.label?
              title.text item.label[0]
            el.append title
  
            description = $('<p></p>');
            if item.description?
              description.text item.description[0]
            el.append description
  
            rendering.badge = badge
            rendering.description = description
            rendering.title = title
  
            width = 2*(item.rank?[0] || 1)
            height = 2*(item.rank?[0] || 1)
  
            classes = ""
            if item.class?
              classes = item.class.join " "
  
            el.attr
              class: "tile width#{width} height#{height} #{classes}"
  
  
            rendering.update = (item) -> 
              if item.description?
                description.text item.description[0]
              else
                description.text ''
              if item.label?
                title.text item.label[0]
              else
                title.text ''
              if item.badge?
                badge.text item.badge[0]
              else
                badge.text ''
  
            rendering.remove = ->
  
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
            rendering
  
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
            console.log "Rendering itemlink", item
            linkedItem = model.getItem item.link?[0]
            console.log "linked item", linkedItem
            if linkedItem?.restType?
              p = $("<p class='type'></p>")
              p.text linkedItem.restType[0]
              $(rendering.el).append(p)
  
            $(rendering.el).click ->
              item = model.getItem itemId
              options.application().nextState
                parent: item.link[0]
  
          that.addLens 'TextSection', (el, presentation, model, itemId) ->
            rendering = {}
            data = model.getItem itemId
            if data.order?
              rendering.order = data.order[0]
            width = data.width?[0] || 6
            el.attr
              class: "tile text width#{width}"
              #style: "width: 32%"
  
            el.append($("<h2>#{data.label?[0]||''}</h2>"))
            el.append($(data.content?[0] || ""))
  
            el.find("a").each (idx, a) ->
              href = $(a).attr 'href'
              if href[0] == '#'
                targetId = href[1..]
                $(a).click ->
                  options.application().nextState
                    parent: targetId
  
  
            rendering.el = el
            rendering.update = (item) ->
              # we don't bother with updates for now - we don't expect them
              # to happen without a reload of the entire page from the server
            rendering.remove = ->
              el.remove()
  
            rendering
  
  
          that.addLens 'FactSheet', (el, presentation, model, itemId) ->
            rendering = {}
  
            data = model.getItem itemId
            if data.order?
              rendering.order = data.order[0]
            templateName = data?.restType?[0]
            template = sga.template.factsheet[templateName]
            return if !templateName? or !template?
  
            content = template(data)
            el.attr
              class: "tile width6 height2 subhead"
            el.append($(content))
            rendering.el = el
  
            rendering.update = (item) ->
              content = template(item)
              el.empty()
              el.append($(content))
   
            rendering.remove = ->
              el.remove()
              
            rendering

  sga.namespace 'template', (template) ->
    t = (s) -> 
      (d) -> _.template(s, d, {variable: 'data'})
  
    _.templateSettings =
      interpolate: /\{\{(.*?)\}\}/g
      escape: /\{\[(.*?)\]\}/g
      evaluate: /\[\[(.*?)\]\]/g
  
    template.namespace 'factsheet', (fs) ->
      fs.Manifest = t """
        <h2>{{ data.label[0] }}</h2>
        <p class='type'>Manifest</p>
        <p><a href="/m/{{ data.parent[0] }}">Play Manifest</a></p>
      """
      fs.Sequence = t """
        <h2>{{ data.label[0] }}</h2>
        <p class='type'>Sequence</p>
      """
      fs.Canvas = t """
        <h2>{{ data.label[0] }}</h2>
        <p class='type'>Canvas ({{ data.width[0] }} x {{ data.height[0] }})</p>
      """

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
          modelCallbacks = {}
  
          that.addModel = (nom, model) -> 
            models[nom] = model
            if modelCallbacks[nom]?
              cb(model) for cb in modelCallbacks[nom]
            delete modelCallbacks[nom]
  
          that.onModel = (nom, cb) ->
            if models[nom]?
              cb(models[nom])
            else
              modelCallbacks[nom] ?= []
              modelCallbacks[nom].push cb
  
          that.model = (nom) -> models[nom]
  
          that.dataStore.data.withParent = (p) ->
            objects = MITHGrid.Data.Set.initInstance [ p ]
            that.dataStore.data.getSubjectsUnion(objects, "parent").items()
  
          that.ready ->
            that.events.onMetroParentChange.addListener (p) ->
              that.dataView.metroItems.setKey p
              item = that.dataStore.data.getItem p
              if item.label?
                $('#section-header').text item.label[0]
              if p == "top"
                $('#section-header').text "Home"
              if item.restType? && that.getAuthenticated()
                $('#li-edit').show()
                $('#li-trash').show()
              else
                $('#li-edit').hide()
                $('#li-trash').hide()
  
            that.events.onMetroModeChange.addListener (m) ->
              #if m == "List"
              #  that.presentation.list.show()
              #  that.presentation.item.hide()
              #else
              #  that.presentation.list.hide()
              #  that.presentation.item.show()
  
            that.events.onAuthenticatedChange.addListener (a) ->
              if a
                $("#menu-settings").show()
              else
                $("#menu-settings").hide()
  
            that.setMetroMode("List")
  
            that.dataView.metroItems.events.onModelChange.addListener (model, itemIds) ->
              for id in itemIds
                item = model.getItem id
                if item.type and ("Command" in item.type)
                  liId = '#li-' + item.commandType[0]
                  if model.contains(id) and (!item.requiresAuthenticated?[0] or that.getAuthenticated())
                    $(liId).show()
                  else
                    $(liId).hide()

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

  $ ->
    # Manifest-new-form
    # Sequence-new-form
    # Canvas-new-form
    # ManifestComponent-new-form
  
    app = sga.application.top.instance
  
    app.ready ->
      sga.namespace "modals", (modals) ->
        modals.namespace "create", (create) ->
          for model in ['Manifest', 'Sequence', 'Canvas', 'Layer', 'Zone', 'Image']
            do (model) ->
              app.onModel model, (m) ->
                create[model] = sga.component.newItemForm.initInstance $("##{model}-new-form"),
                  application: -> app
                  model: m
  
        modals.namespace "update", (update) ->
          for model in ['Manifest', 'Sequence', 'Canvas', 'Layer', 'Zone']
            do (model) ->
              app.onModel model, (m) ->
                update[model] = sga.component.editItemForm.initInstance $("##{model}-edit-form"),
                  application: -> app
                  model: m
  
        app.onModel 'Manifest', (m) ->
          sga.component.addItemForm.initInstance $("#ManifestComponent-new-form"),
            model: m
            application: -> app
        app.onModel 'Sequence', (s) ->
          sga.component.addItemForm.initInstance $("#SequenceComponent-new-form"),
            model: s
            application: -> app
        app.onModel 'Image', (i) ->
          app.onModel 'ImageAnnotation', (ia) ->
            sga.component.addAnnotationForm.initInstance $("#ImageAnnotation-new-form"),
              model: i
              annotationModel: ia
              annotationTypes: [ 'image_annotations' ]
              application: -> app
              parentProperty: 'image'

MITHGrid.defaults 'sga.component.modalForm',
  events:
    onAction: null

MITHGrid.defaults 'sga.application.top',
  dataStores:
    data:
      types:
        SectionLink: {}
        URLLink: {}
        Project: {}
        Library: {}
        Board: {}
        BoardRank: {}
        Page: {}
        PagePart: {}
      properties:
        board_ranks:
          valueType: 'item'
        pages:
          valueType: 'item'
        parent:
          valueType: 'item'
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
    Authenticated:
      is: 'rw'
      default: true
  presentations:
    list:
      type: sga.presentation.metro
      container: " .metro-hub"
      dataView: 'metroItems'
    nav:
      type: sga.presentation.metroNav
      container: " .metro-nav"
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
          <ul class="nav pull-right" id="menu-settings" style="display: none;">
             <li class="dropdown">
               <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                 Account
                 <b class="caret"></b>
               </a>
               <ul class="dropdown-menu">
                 <li><a href="#" id="cmd-user"><i class="icon-user icon-white"></i> Profile</a></li>
                 <li><a href="#" id="cmd-cog"><i class="icon-cog icon-white"></i> Settings</a></li>
                 <li class="divider"></li>
                 <li><a href="#" id="cmd-off"><i class="icon-off icon-white"></i> Logout</a></li>
               </ul>
             </li>
          </ul>
           <ul class="nav">
             <li class="dropdown">
               <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                 <span id="section-header">Home</span>
                 <b class="caret"></b>
               </a>
              <ul class='dropdown-menu metro-nav'></ul>
             </li>
           </ul>
         </div>
       </div>
     </div>
    </div>
    <div class="row-fluid">
      <div class="span12">
        <ul class="breadcrumb metro-breadcrumb" style="display: none;">
        </ul>
      </div>
    </div>
    <div class="row-fluid">
      <div class="span12 metro-hub"></div>
    </div>
    <div style="clear: both;" class="row-fluid"></div>
    <div class="navbar navbar-fixed-bottom">
      <div class="navbar-inner">
        <div class="container">
          <ul class="nav pull-right" id="right-commands">
            <li class="divider-vertical"></li>
            <li id="li-trash" style="display: none;"><a href="#" id="cmd-trash"><i class="icon-trash icon-white"></i></a></li>
            <li id="li-remove" style="display: none;"><a href="#" id="cmd-remove"><i class="icon-remove icon-white"></i></a></li>
            <li id="li-edit" style="display: none;"><a href="#" id="cmd-edit"><i class="icon-edit icon-white"></i></a></li>
            <li id="li-plus" style="display: none;"><a href="#" id="cmd-plus"><i class="icon-plus icon-white"></i></a></li>
          </ul>
          <ul class="nav pull-left">
            <li id="li-home"><a href="#" id="cmd-home"><i class="icon-home icon-white"></i></a></li>
          </ul>
        </div>
      </div>
    </div>
  """
