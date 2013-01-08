<%args>
$.canvas
</%args>
<%augment form($title, $button, $cancel)>
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('label') %>">
      <input type="text" name="label" class="span12" placeholder="Canvas label..." value="<% $.form_data->{label} | H %>">
    </div>
  </div>
  <div class="row-fluid">
    <div class="control-group">
      <label class="control-label">Extents</label>
      <div class="controls">
        <div class="input-append">
        <input type="text" name="width" class="inline span2" placeholder="Width..." value="<% $.form_data->{width} | H %>"><span class="add-on">px</span>
        &times;
        <input type="text" name="height" class="inline span2" placeholder="Height..." value="<% $.form_data->{height} | H %>"><span class="add-on">px</span>
        </div>
      </div>
    </div>
  </div>
</%augment>
