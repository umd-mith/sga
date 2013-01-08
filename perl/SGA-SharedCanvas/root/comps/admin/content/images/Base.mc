<%args>
$.canvas
</%args>
<%augment form($title, $button, $cancel_url)>
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('label') %>">
      <input type="text" name="label" class="span12" placeholder="Image label..." value="<% $.form_data->{label} | H %>">
    </div>
  </div>
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('url') %>">
      <input type="text" name="url" class="span12" placeholder="Image url..." value="<% $.form_data->{url} | H %>">
    </div>
  </div>
</%augment>
