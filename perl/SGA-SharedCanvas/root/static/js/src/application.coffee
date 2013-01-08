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
