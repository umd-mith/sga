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
