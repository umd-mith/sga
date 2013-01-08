<%args>
$.images => sub { [] }
$.canvases => sub { [] }
$.zones => sub { [] }
</%args>
<%augment form($title, $button, $cancel_url)>
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('label') %>">
      <input type="text" name="label" class="span12" placeholder="Annotation label..." value="<% $.form_data->{label} | H %>">
    </div>
  </div>
% if(@{$.images}) {
  <div class="row-fluid">
    <div class="control-group">
      <label class="control-label">Image</label>
      <div class="controls">
        <select name="image">
%         for my $image (@{$.images}) {
            <option value="<% $image->id %>"
%             if(defined($.form_data->{image}) && $image->id eq $.form_data->{image}) {
                selected
%             }
            ><% $image->label | H %></option>
%         }
        </select>
      </div>
    </div>
  </div>
% }
% if(@{$.canvases} || @{$.zones}) {
  <div class="row-fluid">
    <h3>Target</h3>
    <p>Select one or more of the following items as the target of this image.</p>
%   if(@{$.canvases}) {
%     my %checked = map { $_ => 1 } @{$.form_data->{_embedded}->{canvases}||[]};
      <div class="control-group">
        <label class="control-label">Canvas</label>
        <div class="controls">
          <select name="embedded[canvases]" multiple>
%           for my $canvas (@{$.canvases}) {
              <option value="<% $canvas->id %>"
%               if($checked{$canvas->id}) {
                  selected
%               }
              ><% $canvas -> label | H %></option>
%           }
          </select>
        </div>
      </div>
%   }
  </div>
% }
</%augment>
