<%args>
$.sequence
$.canvases => sub { +{} }
</%args>
<%augment form($title, $button, $cancel_url)>
% my %own_canvases = map { $_ => 1 } @{$.form_data->{canvases}||[]};
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('label') %>">
      <input type="text" name="label" class="span12" placeholder="Sequence label..." value="<% $.form_data->{label} | H %>">
    </div>
  </div>
  <div class="row-fluid" id="canvases-group">
    <div class="control-group offset1 span5">
      <h3>Canvases</h3>
      <ul class="sortable canvas" id="canvases">
%       for my $canvas (@{$.form_data->{canvases}||[]}) {
          <li class="canvas" data-canvas="<% $canvas %>"><% $.canvases->{$canvas}->label %></li>
%       }
      </ul>
      <input type="hidden" name="_embedded[canvases]" id="canvas-list" value="" />
    </div>
    <div class="span5">
      <h3>Available Canvases</h3>
      <ul class="canvas" id="available-canvases">
%       for my $canvas (keys %{$.canvases}) {
%         next if $own_canvases{$canvas};
          <li class="canvas" data-canvas="<% $canvas %>"><% $.canvases->{$canvas}->label %></li>
%       }
      </ul>
  </div>
  <script>
    $(function() {
      $("#canvases").sortable({
        revert: true,
        connectWith: "ul#available-canvases",
        containment: "#canvases-group",
      });
      $("#available-canvases").sortable({
        revert: true,
        connectWith: "ul#canvases",
        containment: "#canvases-group"
      });
      $("form.well.form-horizontal").on("submit", function() {
        var canvases = [];
        $("ul#canvases li").each(function(idx, el) {
          canvases.push($(el).data('canvas'));
        });
        console.log("Canvases:", canvases);
        $("#canvas-list").val(canvases.join(", "));
      });
    });
  </script>
</%augment>
