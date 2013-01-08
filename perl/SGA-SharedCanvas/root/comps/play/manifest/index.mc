<%args>
$.resource
</%args>
<%method headers>
  <script src="<% $c->uri_for('/static/js/mithgrid.min.js') %>"></script>
  <script src="<% $c->uri_for('/static/js/jquery.svg.min.js') %>"></script>
  <script src="<% $c->uri_for('/static/js/shared-canvas.js') %>"></script>
  <% inner() %>
</%method>
<div class="row-fluid">
<div class="span12">
<form class="well form-inline">
    <div style="float: right">
      <a href="#" class="btn" id="prev-page"><i class="icon icon-step-backward"></i></a>
      <a href="#" class="btn" id="next-page"><i class="icon icon-step-forward"></i></a>
    </div>
    <label>Sequence:</label>
    <select id="sequence"></select>
    &nbsp;
    <label>Canvas:</label>
    <span id="canvas-label"></span>
</form>
</div>
</div>
<div class="well">
  <div class="row-fluid">
    <div class="span6" style="padding-left: 2%; text-align: center;">
      <div class="canvas" data-types="Image" data-manifest="<% $.resource->link %>"></div>
    </div>
    <div class="span6" style="padding-left: 2%; text-align: center;">
      <div class="canvas" data-types="Text" data-manifest="<% $.resource->link %>"></div>
    </div>
  </div>
</div>
<script type="text/javascript">
  $(function() {
    var builder = SGA.Reader.Application.SharedCanvas.builder({ 
    });
    builder.onManifest("<% $.resource->link %>", function(app) {
      var filter = SGA.Reader.Component.SequenceSelector.initInstance("#sequence", {
        dataView: app.dataView.sequences
      });
      filter.events.onSequenceChange.addListener( app.setSequence );
      app.setSequence( filter.getSequence() );
      app.events.onCanvasChange.addListener(function(c) {
        var item = app.dataStore.data.getItem(c);
        $("#canvas-label").text(item.label[0]);
      });

      $("#prev-page").click(function() {
        var p = app.getPosition();
        if(p > 0) {
          p -= 1;
          app.setPosition(p);
        }
      });
      $("#next-page").click(function() {
        var p = app.getPosition();
        var seq = app.dataStore.data.getItem(app.getSequence());
        if(p < seq.sequence.length-1) {
          p += 1;
          app.setPosition(p);
        }
      });
      app.events.onPositionChange.addListener(function(p) {
        if(p > 0) {
          $("#prev-page").removeClass("disabled");
        }
        else {
          $("#prev-page").addClass("disabled");
        }
        var seq = app.dataStore.data.getItem(app.getSequence());
        console.log("seq length", seq.sequence.length, "p", p);
        if(p < seq.sequence.length-1) {
          $("#next-page").removeClass("disabled");
        }
        else {
          $("#next-page").addClass("disabled");
        }
      });
    });
  });
</script>
