# # Components

SGAReader.namespace "Component", (Component) ->

  #
  # ## Component.ProgressBar
  #

  Component.namespace "ProgressBar", (ProgressBar) ->

    #
    # This component manages the display of a progress bar based on
    # the Twitter Bootstrap progress bar component.
    #
    # The component has two variables: Numerator and Denominator.
    #

    ProgressBar.initInstance = (args...) ->
      MITHgrid.initInstance "SGA.Reader.Component.ProgressBar", args..., (that, container) ->

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

  #
  # ## Component.SequenceSelector
  #

  Component.namespace "SequenceSelector", (SequenceSelector) ->

    #
    # This component manages the options of a select HTML form element.
    # 
    # The component has one variable: Sequence.
    #
    # The container should be a <select></select> element.
    #

    SequenceSelector.initInstance = (args...) ->
      MITHgrid.Presentation.initInstance "SGA.Reader.Component.SequenceSelector", args..., (that, container) ->
        options = that.options
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

        that.events.onSequenceChange.addListener (v) ->
          $(container).val(v)

        that.finishDisplayUpdate = ->
          that.setSequence $(container).val()

  #
  # ## Component.Slider
  #

  Component.namespace "Slider", (Slider) ->

    #
    # This component manages an HTML5 slider input element.
    #
    # This component has three variables: Min, Max, and Value.
    #
    Slider.initInstance = (args...) ->
      MITHgrid.initInstance "SGA.Reader.Component.Slider", args..., (that, container) ->
        that.events.onMinChange.addListener (n) ->
          $(container).attr
            min: n
        that.events.onMaxChange.addListener (n) ->
          $(container).attr
            max: n
        that.events.onValueChange.addListener (n) -> $(container).val(n)
        $(container).change (e) -> that.setValue $(container).val()

  #
  # ## Component.PagerControls
  #

  Component.namespace "PagerControls", (PagerControls) ->

    #
    # This component manages a set of Twitter Bootstrap buttons that display
    # the step forward, step backward, fast forward, and fast backward icons.
    #
    # This component has three variables: Min, Max, and Value.
    #

    PagerControls.initInstance = (args...) ->
      MITHgrid.initInstance "SGA.Reader.Component.PagerControls", args..., (that, container) ->
        firstEl = $(container).find(".icon-fast-backward").parent()
        prevEl = $(container).find(".icon-step-backward").parent()
        nextEl = $(container).find(".icon-step-forward").parent()
        lastEl = $(container).find(".icon-fast-forward").parent()

        that.events.onMinChange.addListener (n) ->
          if n < that.getValue()
            firstEl.removeClass "disabled"
            prevEl.removeClass "disabled"
          else
            firstEl.addClass "disabled"
            prevEl.addClass "disabled"

        that.events.onMaxChange.addListener (n) ->
          if n > that.getValue()
            nextEl.removeClass "disabled"
            lastEl.removeClass "disbaled"
          else
            nextEl.addClass "disabled"
            lastEl.addClass "disabled"

        that.events.onValueChange.addListener (n) ->
          if n > that.getMin()
            firstEl.removeClass "disabled"
            prevEl.removeClass "disabled"
          else
            firstEl.addClass "disabled"
            prevEl.addClass "disabled"

          if n < that.getMax()
            nextEl.removeClass "disabled"
            lastEl.removeClass "disabled"
          else
            nextEl.addClass "disabled"
            lastEl.addClass "disabled"

        $(prevEl).click (e) ->
          e.preventDefault()
          that.addValue -1
        $(nextEl).click (e) ->
          e.preventDefault()
          that.addValue 1
        $(firstEl).click (e) ->
          e.preventDefault()
          that.setValue that.getMin()
        $(lastEl).click (e) ->
          e.preventDefault()
          that.setValue that.getMax()

  #
  # ## Component.ImageControls
  #
  Component.namespace "ImageControls", (ImageControls) ->
    ImageControls.initInstance = (args...) ->
      MITHgrid.initInstance "SGA.Reader.Component.ImageControls", args..., (that, container) ->        
        resetEl = $(container).find(".icon-picture").parent()
        inEl = $(container).find(".icon-zoom-in").parent()
        outEl = $(container).find(".icon-zoom-out").parent()
        marqueeEl = $(container).find(".icon-eye-open").parent()

        $(resetEl).click (e) ->
          e.preventDefault()
          that.setZoom that.getMinZoom()
          that.setImgPosition 
            topLeft:
              x: 0,
              y: 0,
            bottomRight:
              x: 0,
              y: 0

        $(inEl).click (e) ->
          e.preventDefault()
          zoom = that.getZoom()
          if Math.floor zoom+1 <= that.getMaxZoom()
            that.setZoom Math.floor zoom+1

        $(outEl).click (e) ->
          e.preventDefault()
          zoom = that.getZoom()
          minZoom = that.getMinZoom()
          if Math.floor zoom-1 > minZoom
            that.setZoom Math.floor zoom-1
          else if Math.floor zoom-1 == Math.floor minZoom
            that.setZoom minZoom

        $(marqueeEl).click (e) ->
          e.preventDefault()
          marquees = $('.marquee')
          marquees.each (i, m) ->
            m = $(m)            
            if m.css("display") != "none"
              m.hide()
            else 
              m.show()

  #
  # ## Component.SearchBox
  #
  Component.namespace "SearchBox", (SearchBox) ->
    SearchBox.initInstance = (args...) ->
      MITHgrid.initInstance "SGA.Reader.Component.SearchBox", args..., (that, service) ->        
        container = args[0]
        that.setServiceURL service

        # console.log $(container).closest('form')

        $(container).closest('form').submit (e) ->
          e.preventDefault()
          val = $(container).val()
          if !val.match '^\s*$'
            that.setQuery val
          false
          

        # On submit function go here and they will simply change the variable Query