(function ($) { 

  // UI fixes
  $("#collapse-one").collapse("hide");

  // MAIN SC SETUP CODE

  var builder = SGA.Reader.Application.SharedCanvas.builder({
    spinner: SGA.Reader.Component.Spinner.initInstance($("#loading-progress")),
    searchBox: SGA.Reader.Component.SearchBox.initInstance("#searchbox", "http://ec2-107-22-87-255.compute-1.amazonaws.com/annotate?")
  });

  if($.fn.popover != null) {
    $("#metadata").popover({
      title: "About this Manifest",
      content: function() {
        return "<p>We'll build up a list of items from the manifest.</p>";
      },
      html: true,
      animation: true
    });
  }

  builder.onManifest(
    $('*[data-manifest]').attr('data-manifest')
  , function(app) {
    var filter, pageSlider, pager;

    filter = SGA.Reader.Component.SequenceSelector.initInstance("#sequence", { 
      dataView: app.dataView.sequences
    });

    pageSlider = SGA.Reader.Component.Slider.initInstance("#page-location");

    pager = SGA.Reader.Component.PagerControls.initInstance("#pager-controls");

    // modeControls = SGA.Reader.Component.ModeControls.initInstance("#mode-controls");

    app.imageControls = SGA.Reader.Component.ImageControls.initInstance("#view-controls");

    pageSlider.events.onValueChange.addListener( app.setPosition );
    pager.events.onValueChange.addListener( app.setPosition );

    app.events.onPositionChange.addListener( function(n) {
      app.lockPosition();
      pageSlider.setValue(n);
      pager.setValue(n);
      app.unlockPosition();
    } );

    filter.events.onSequenceChange.addListener( app.setSequence );

    app.events.onSequenceChange.addListener( function(s) {
      var seq = app.dataStore.data.getItem(s);
      if(seq != null && seq.sequence != null) {
        pageSlider.setMin(0);
        pager.setMin(0);

        pageSlider.setMax(seq.sequence.length-1);
        pager.setMax(seq.sequence.length-1);

        if(!(app.getPosition() != null)) {
          app.setPosition(0);
        }
      }
    });

    app.setSequence( filter.getSequence() );

    app.events.onCanvasChange.addListener(function(c) {
      var item = app.dataStore.data.getItem(c);
      if(item.label !== undefined) {
        $("#canvas-label").text(item.label[0]);
      }
      else {
        $("#canvas-label").text("(no label)");
      }
    });

  });
})(jQuery);