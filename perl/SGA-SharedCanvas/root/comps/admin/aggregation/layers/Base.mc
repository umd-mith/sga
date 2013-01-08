<%args>
$.layer
$.image_annotation_lists => sub { [] }
</%args>

<%augment form($title, $button, $cancel_url)>
% my %own_image_annotation_lists = map { $_ => 1 } @{$.form_data->{_embedded}{image_annotation_lists} || []};
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('label') %>">
      <input type="text" name="label" class="span12" placeholder="Layer label..." value="<% $.form_data->{label} | H %>">
    </div>
  </div>
% if(@{$.image_annotation_lists}) {
  <div class="row-fluid">
    <input type="hidden" name="embedded[image_annotation_lists]" value="" />
    <h3>Image Annotation Lists</h3>
    <div class="span10 offset1">
%     for my $list (@{$.image_annotation_lists}) {
        <label class="checkbox">
          <input type="checkbox" name="embedded[image_annotation_lists]" value="<% $list -> id %>"
%           if($own_image_annotation_lists{$list->id}) {
              checked
%           }
          class="inline" > <% $list -> label | H %>
        </label>
%     }
    </div>
  </div>
% }
</%augment>
