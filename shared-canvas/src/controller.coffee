# # Controllers

SGAReader.namespace "Controller", (Controller) ->
  Controller.namespace "ModeSelector", (ModeSelector) ->
    ModeSelector.initInstance = (args...) ->
      MITHgrid.Controller.initInstance "SGA.Reader.Controller.ModeSelector", args..., (that, container) ->
        set = []
        

        that.applyBindings = (binding, options) ->
          set.push binding

          el = binding.locate ''
          binding.$clickHandler = (e) ->
            e.preventDefault()
            binding.events.onModeSelect.fire(options.mode)
            for b in set
              b.eventModeSelect?(options.mode)
          el.bind 'click', binding.$clickHandler

          binding.eventModeSelect = (m) ->
            if options.mode == m
              el.addClass 'active'
              binding.onSelect()
            else
              el.removeClass 'active'
              binding.onUnselect()

          binding.onSelect = ->
          binding.onUnselect = ->

        that.removeBindings = (binding) ->
          set = (s for s in set when s != binding)
          el.unbind 'click', binding.$clickHandler

