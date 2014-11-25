(function ($) { 
  'use strict';

  var manifestURL = $("#SGASharedCanvasViewer").data("manifest");

  var sc = new SGASharedCanvas.Application({"manifest":manifestURL});

})(jQuery);