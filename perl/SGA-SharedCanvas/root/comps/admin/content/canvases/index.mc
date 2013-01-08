<%args>
$.canvases => sub { [] }
</%args>
% $.IndexTable {{
%   $.IndexHead {{
      <% $.IndexHeadName("Canvas") %>
      <% $.IndexHeadCol("", "Height") %>
      <% $.IndexHeadCol("", "Width") %>
      <% $.IndexHeadActions("Actions") %>
%   }}
%   $.IndexBody {{
%     for my $canvas (@{$.canvases}) {
%       $.IndexItem {{
%         $.IndexItemName("", "/admin/canvas/".$canvas->id) {{
            <% $canvas->label %>
%         }}
%         $.IndexItemCol("") {{
            <% $canvas->height %>
%         }}
%         $.IndexItemCol("") {{
            <% $canvas->width %>
%         }}
%         $.IndexItemActions {{
            <% $.IndexItemAction(
                 0,
                 "",
                 "minus-sign",
                 "Remove",
               ) %>
%         }}
%       }}
%     }
%   }}
% }}
<a href="<% $c->uri_for("/admin/canvas/new") %>" class="btn btn-primary">
  New Canvas
</a>
<a href="<% $c->uri_for("/admin/canvas/new-series") %>" class="btn">
  New Canvas Series
</a>
