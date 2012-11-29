# # Component
SGAReader.namespace "Component", (Component) ->
  Component.namespace "ProgressBar", (ProgressBar) ->
    ProgressBar.initInstance = (args...) ->
      MITHGrid.initInstance "SGA.Reader.Component.ProgressBar", args..., (that, container) ->
        that.events.onNumeratorChange.addListener (n) ->
          percent = parseInt(100 * n / that.getDenominator(), 10)
          percent = 100 if percent > 100
          $(container).find(".bar").css("width", percent + "%")
        that.events.onDenominatorChange.addListener (d) ->
          percent = parseInt(100 * that.getNumerator() / d, 10)
          percent = 100 if percent > 100
          $(container).find(".bar").css("width", percent + "%")

        that.show = -> 
          $(container).show()
        that.hide = -> 
          $(container).hide()

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
