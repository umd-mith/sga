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
