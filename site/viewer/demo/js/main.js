(function ($) { 
  'use strict';

  var manifestURL = $("#SGASharedCanvasViewer").data("manifest");

  var sc = new SGASharedCanvas.Application({"manifest":manifestURL, "searchService":"http://107.20.241.32/annotate?"});

})(jQuery);