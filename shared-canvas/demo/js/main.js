(function ($) { 

  // UI fixes
  $("#collapse-one").collapse("hide");

  // MAIN SC SETUP CODE

  var builder = SGA.Reader.Application.SharedCanvas.builder({
    spinner: SGA.Reader.Component.Spinner.initInstance($("#loading-progress")),
    searchBox: SGA.Reader.Component.SearchBox.initInstance("#searchbox", "http://107.20.241.32/annotate?")
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

    app.modeControls = SGA.Reader.Component.ModeControls.initInstance("#mode-controls");

    limitViewControls = SGA.Reader.Component.LimitViewControls.initInstance("#hand-view-controls", {
      onModeChange : app.modeControls.events.onModeChange
    });

    ModeLayers = SGA.Reader.Component.ModeLayers.initInstance("#ModeLayers", { 
      dataView: app.dataStore.data,
      pagerEvt: app.events.onCanvasChange,
      getMode: app.modeControls.getMode,
      onModeChange : app.modeControls.events.onModeChange
    });    

    app.imageControls = SGA.Reader.Component.ImageControls.initInstance("#view-controls");

    pageSlider.events.onValueChange.addListener( app.setPosition );
    pager.events.onValueChange.addListener( app.setPosition );

    app.events.onPositionChange.addListener( function(n) {
      app.lockPosition();
      if (n != -1) {
        pageSlider.setValue(n);
        pager.setValue(n);
      }
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
      var meta = app.getCanvasMetadata(c);
      
      // TOP METADATA      
      for (var k in meta) {
        var v = meta[k]
        if (v !== undefined) {
          $("#meta-"+k).next().text(v);
        }
        else {
          $("#meta-"+k).next().text("Not specified");
        }
      }

      // PAGE VIEW METADATA
      if(meta.workTitle !== undefined) {
        $("#sc-work-title").text(meta.workTitle);        
      }
      else {
        $("#sc-work-title").parent().remove();
      }
      if(meta.rangeTitle !== undefined) {
        $("#sc-range-title").text(meta.rangeTitle.join("; "));
      }
      else {
        $("#sc-range-title").parent().remove();
      }
      if(meta.canvasTitle !== undefined) {
        $("#sc-canvas-title").text(meta.canvasTitle);
        $("#meta-workFolio").next().text(meta.canvasTitle);
      }
     else {
        $("#sc-canvas-title").parent().remove();
        $("#meta-workFolio").next().text("Not specified");
      }

      // CITATION
      if(meta.workAuthor !== undefined) {
        authorParts = meta.workAuthor.split(" ");
        last = authorParts[authorParts.length-1];
        initials = "";
        for (i=0; i<authorParts.length-1; i++) { 
          initials += authorParts[i].substring(0,1) + ". "; 
        }
        author = last + ", " + initials;
        $("#cite-author").text(author);
      }
      if(meta.workDate !== undefined) {
        dateParts = meta.workDate.split(" ");
        year = dateParts[dateParts.length-1];
        $("#cite-year").text(year);
      }
      if(meta.workTitle !== undefined) {
        notebook = (meta.workNotebook !== undefined) ? meta.workNotebook : "";
        title = meta.workTitle + " - " + notebook;
        $("#cite-title").text(title);
      }
      if(meta.canvasTitle !== undefined) {
        $("#cite-page").text(meta.canvasTitle);
      }
      $("#cite-url").text(document.URL);
    });

  });
})(jQuery);