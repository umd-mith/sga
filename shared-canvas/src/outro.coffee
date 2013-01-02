
)(jQuery, MITHGrid)

MITHGrid.defaults 'SGA.Reader.Application.SharedCanvas',
  dataStores:
    data:
      types:
        Sequence: {}
        Canvas: {}
      properties:
        target:
          valueType: 'item'
  dataViews:
    canvasAnnotations:
      dataStore: 'data'
      type: MITHGrid.Data.SubSet
      expressions: [ '!target' ]
    sequences:
      dataStore: 'data'
      types: [ 'Sequence' ]
  variables:
    Canvas:   { is: 'rw' }
    Sequence: { is: 'rw' }
    Position: { is: 'lrw', isa: 'numeric' }

MITHGrid.defaults 'SGA.Reader.Component.Slider',
  variables:
    Min:   { is: 'rw', isa: 'numeric' }
    Max:   { is: 'rw', isa: 'numeric' }
    Value: { is: 'rw', isa: 'numeric' }

MITHGrid.defaults 'SGA.Reader.Component.PagerControls',
  variables:
    Min:   { is: 'rw', isa: 'numeric' }
    Max:   { is: 'rw', isa: 'numeric' }
    Value: { is: 'rw', isa: 'numeric' }

MITHGrid.defaults 'SGA.Reader.Component.SequenceSelector',
  variables:
    Sequence: { is: 'rw' }

MITHGrid.defaults 'SGA.Reader.Component.ProgressBar',
  variables:
    Numerator:   { is: 'rw', default: 0, isa: 'numeric' }
    Denominator: { is: 'rw', default: 1, isa: 'numeric' }
  viewSetup: """
    <div class="progress progress-striped active">
      <div class="bar" style="width: 0%;"></div>
    </div>
  """

MITHGrid.defaults 'SGA.Reader.Presentation.Canvas',
  variables:
    Canvas: { is: 'rw' }
    Scale:  { is: 'rw', isa: 'numeric' }

MITHGrid.defaults 'SGA.Reader.Data.Manifest',
  variables:
    ItemsToProcess: { is: 'rw', default: 0, isa: 'numeric' }
    ItemsProcessed: { is: 'rw', default: 0, isa: 'numeric' }
