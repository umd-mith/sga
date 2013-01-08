<%args>
$.image_annotation_lists => sub { [] }
</%args>
% $.IndexTable {{
%   $.IndexHead {{
      <% $.IndexHeadName("Image Annotation List") %>
      <% $.IndexHeadActions("Actions") %>
%   }}
%   $.IndexBody {{
%     for my $list (@{$.image_annotation_lists}) {
%       $.IndexItem {{
%         $.IndexItemName("", "/admin/image_annotation_list/".$list->id) {{
            <% $list->label %>
%         }}
%         $.IndexItemActions {{
            <% $.IndexItemAction(
                 0,
                 "/admin/image_annotation_list/" . $list->id . "/delete",
                 "minus-sign",
                 "Remove"
               ) %>
%         }}
%       }}
%     }
%   }}
% }}
<a href="<% $c->uri_for("/admin/image_annotation_list/new") %>" class="btn btn-primary">
  New Image Annotation List
</a>
