<%args>
$.manifest
$.sequences => sub { [] }
$.layers => sub { [] }
</%args>

<%augment form($title, $button, $cancel_url)>
% my %own_sequences = map { $_ => 1 } @{$.form_data->{sequences} || []};
% my %own_layers =    map { $_ => 1 } @{$.form_data->{layers}    || []};
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('label') %>">
      <input type="text" name="label" class="span12" placeholder="Manifest label..." value="<% $.form_data->{label} | H %>">
    </div>
  </div>
  <div class="row-fluid">
    <div class="control-group offset1 span11<% $.formClasses('object_creator') %>">
      <input type="text" name="object_creator" class="span12" placeholder="Manifest creator..." value="<% $.form_data->{object_creator} | H %>">
    </div>
  </div>
% if(@{$.sequences}) {
  <input type="hidden" name="_embedded[sequences]" value="" />
  <div class="row-fluid">
    <h3>Sequences</h3>
    <div class="span10 offset1">
%     for my $seq (@{$.sequences}) {
        <label class="checkbox">
          <input type="checkbox" name="_embedded[sequences]" value="<% $seq -> id %>"
%           if($own_sequences{$seq->id}) {
              checked
%           }
          class="inline" > <% $seq -> label | H %>
        </label>
%     }
    </div>
  </div>
% }
% if(@{$.layers}) {
  <input type="hidden" name="_embedded[layers]" value="" />
  <div class="row-fluid">
    <h3>Layers</h3>
    <div class="span10 offset1">
%     for my $layer (@{$.layers}) {
        <label class="checkbox">
          <input type="checkbox" name="_embedded[layers]" value="<% $layer -> id %>"
%           if($own_layers{$layer->id}) {
              checked
%           }
          class="inline" > <% $layer -> label | H %>
        </label>
%     }
    </div>
  </div>
% }
</%augment>
