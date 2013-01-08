<%args>
$.image_annotations => sub { [] }
</%args>
% $.IndexTable {{
%   $.IndexHead {{
      <% $.IndexHeadName("Image Annotation") %>
      <% $.IndexHeadCol("", "Image") %>
      <% $.IndexHeadCol("", "Target") %>
      <% $.IndexHeadActions("Actions") %>
%   }}
%   $.IndexBody {{
%     for my $image (@{$.image_annotations}) {
%       $.IndexItem {{
%         $.IndexItemName("", "/admin/image_annotation/".$image->id) {{
            <% $image->label %>
%         }}
%         $.IndexItemCol("") {{
            <% $image -> image -> id %>
%         }}
%         $.IndexItemCol("") {{
%           if(@{$image -> canvases||[]}) {
              Canvas
%           }
%         }}
%         $.IndexItemActions("") {{
%         }}
%       }}
%     }
%   }}
% }}
<a href="<% $c->uri_for("/admin/image_annotation/new") %>" class="btn btn-primary">
  New Image Annotation
</a>
