
)(jQuery, MITHgrid)

#
# The Application.SharedCanvas object ties together all of the information
# about our view of the manifest, from available sequences and annotations
# to where we are in which sequence. The application object coordinates all
# of the components and presentations concerned with a particular manifest.
#
# The app.dataViews.canvasAnnotations data view will always contain a list
# of annotations directly targeting the current canvas.
#
MITHgrid.defaults 'SGA.Reader.Application.SharedCanvas',
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
      type: MITHgrid.Data.SubSet
      expressions: [ '!target' ]
    sequences:
      dataStore: 'data'
      types: [ 'Sequence' ]
  variables:
    Canvas:   { is: 'rw' }
    Sequence: { is: 'rw' }
    Position: { is: 'lrw', isa: 'numeric' }

#
# The Slider and PagerControls have the same variables so that they can be
# used interchangably.
#
MITHgrid.defaults 'SGA.Reader.Component.Slider',
  variables:
    Min:   { is: 'rw', isa: 'numeric' }
    Max:   { is: 'rw', isa: 'numeric' }
    Value: { is: 'rw', isa: 'numeric' }

MITHgrid.defaults 'SGA.Reader.Component.PagerControls',
  variables:
    Min:   { is: 'rw', isa: 'numeric' }
    Max:   { is: 'rw', isa: 'numeric' }
    Value: { is: 'rw', isa: 'numeric' }

MITHgrid.defaults 'SGA.Reader.Component.SequenceSelector',
  variables:
    Sequence: { is: 'rw' }

#
# We put the view setup here so that we don't have to remember how to
# arrange the Twitter Bootstrap HTML each time. This is looking forward
# to when this is a component outside SGA.
#
MITHgrid.defaults 'SGA.Reader.Component.ProgressBar',
  variables:
    Numerator:   { is: 'rw', default: 0, isa: 'numeric' }
    Denominator: { is: 'rw', default: 1, isa: 'numeric' }
  viewSetup: """
    <div class="progress progress-striped active">
      <div class="bar" style="width: 0%;"></div>
    </div>
  """

MITHgrid.defaults 'SGA.Reader.Component.Spinner',
  viewSetup: """
    <i class="icon-spinner icon-spin icon-3x"></i>
  """

#
# We use the Canvas presentation as the root surface for displaying the
# annotations. Thus, we keep track of which canvas we're looking at.
# The Scale variable will be used to manage zooming.
#
# TODO: Have variables for panning across the canvas.
#
MITHgrid.defaults 'SGA.Reader.Presentation.SVGCanvas',
  variables:
    Canvas: { is: 'rw' }
    Scale:  { is: 'rw', isa: 'numeric' }
    ImgOnly: { is: 'rw' }
    Height: { is: 'rw', isa: 'numeric' }
    Width: { is: 'rw', isa: 'numeric' }
    X: { is: 'rw', isa: 'numeric' }
    Y: { is: 'rw', isa: 'numeric' }

MITHgrid.defaults 'SGA.Reader.Presentation.HTMLCanvas',
  variables:
    Canvas: { is: 'rw' }
    Scale:  { is: 'rw', isa: 'numeric' }
    ImgOnly: { is: 'rw' }
    Height: { is: 'rw', isa: 'numeric' }
    Width: { is: 'rw', isa: 'numeric' }
    X: { is: 'rw', isa: 'numeric' }
    Y: { is: 'rw', isa: 'numeric' }

MITHgrid.defaults 'SGA.Reader.Presentation.TextContent',
  variables:
    Height: { is: 'rw', isa: 'numeric' }
    Width: { is: 'rw', isa: 'numeric' }
    X: { is: 'rw', isa: 'numeric' }
    Y: { is: 'rw', isa: 'numeric' }
    Scale: { is: 'rw', isa: 'numeric' }

MITHgrid.defaults 'SGA.Reader.Presentation.Zone',
  variables:
    Height: { is: 'rw', isa: 'numeric' }
    Width: { is: 'rw', isa: 'numeric' }
    X: { is: 'rw', isa: 'numeric' }
    Y: { is: 'rw', isa: 'numeric' }
    Scale: { is: 'rw', isa: 'numeric' }


MITHgrid.defaults 'SGA.Reader.Presentation.HTMLZone',
  variables:
    Height: { is: 'rw', isa: 'numeric' }
    Width: { is: 'rw', isa: 'numeric' }
    X: { is: 'rw', isa: 'numeric' }
    Y: { is: 'rw', isa: 'numeric' }
    Scale: { is: 'rw', isa: 'numeric' }
#
# The ItemsToProcess and ItemsProcessed are analagous to the
# Numerator and Denominator of the ProgressBar component.
#
MITHgrid.defaults 'SGA.Reader.Data.Manifest',
  variables:
    ItemsToProcess: { is: 'rw', default: 0, isa: 'numeric' }
    ItemsProcessed: { is: 'rw', default: 0, isa: 'numeric' }

MITHgrid.defaults 'SGA.Reader.Component.ImageControls',
  variables:
    Active: { is: 'rw', default: false }
    Zoom: { is: 'rw', default: 0, isa: 'numeric' }
    MaxZoom: { is: 'rw', default: 0, isa: 'numeric' }
    MinZoom: { is: 'rw', default: 0, isa: 'numeric' }
    ImgPosition : {is: 'rw', default: {} }

MITHgrid.defaults 'SGA.Reader.Component.SearchBox',
  variables:
    Field: { is: 'rw', default: false }
    Query: { is: 'rw', default: false }
    ServiceURL: { is: 'rw', default: false }

MITHgrid.defaults 'SGA.Reader.Component.ModeControls',
  variables:
    Mode: { is: 'rw', default: 'normal' }

MITHgrid.defaults 'SGA.Reader.Controller.ModeSelector',
  bind:
    events:
      onModeSelect: null