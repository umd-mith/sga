# # Component
SGAReader.namespace "Component", (Component) ->
  Component.namespace "SequenceSelector", (SequenceSelector) ->
    SequenceSelector.initInstance = (args...) ->
      MITHGrid.Presentation.initInstance "SGA.Reader.Component.SequenceSelector", args..., (that, container) ->
        options = that.options
        # container should be a <select/> element
        that.addLens 'Sequence', (container, view, model, id) ->
          rendering = {}
          item = model.getItem id
          el = $("<option></option>")
          el.attr
            value: id
          el.text item.label?[0]
          $(container).append(el)

        $(container).change ->
          that.setSequence $(container).val()

        that.finishDisplayUpdate = ->
          that.setSequence $(container).val()
