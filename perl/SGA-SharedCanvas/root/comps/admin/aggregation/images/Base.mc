<%args>
$.image_annotation_list
$.image_annotations => sub { [] }
</%args>

<%augment form($title, $button, $cancel_url)>
% my %own_annos = map { $_ => 1 } @{$.form_data->{_embedded}{image_annotations} || []};
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('label') %>">
      <input type="text" name="label" class="span12" placeholder="Image annotation list label..." value="<% $.form_data->{label} | H %>">
    </div>
  </div>
% if(@{$.image_annotations}) {
  <input type="hidden" name="embedded[image_annotations]" value="" />
  <div class="row-fluid">
    <h3>Image Annotations</h3>
    <div class="span10 offset1">
%     for my $anno (@{$.image_annotations}) {
        <label class="checkbox">
          <input type="checkbox" name="embedded[image_annotations]" value="<% $anno -> id %>"
%           if($own_annos{$anno->id}) {
              checked
%           }
          class="inline" > <% $anno -> label | H %>
        </label>
%     }
    </div>
  </div>
% }
</%augment>
