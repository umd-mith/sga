(function ($) { 
  MITHgrid.config.noTimeouts = true;

  // UI fixes
  $("#collapse-one").collapse("hide");

  // EXAMPLE SGA Shared Canvas SETUP CODE

  var builder = SGA.Reader.Application.SharedCanvas.builder();

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
  );
})(jQuery);