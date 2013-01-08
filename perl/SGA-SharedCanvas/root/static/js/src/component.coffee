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
