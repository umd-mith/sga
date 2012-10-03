
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
    Canvas:
      is: 'rw'
    Sequence:
      is: 'rw'
    Position:
      is: 'rw'

MITHGrid.defaults 'SGA.Reader.Component.SequenceSelector',
  variables:
    Sequence:
      is: 'rw'

MITHGrid.defaults 'SGA.Reader.Presentation.Canvas',
  variables:
    Canvas:
      is: 'rw'
    Scale:
      is: 'rw'
