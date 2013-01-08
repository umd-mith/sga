<%args>
$.layers => sub { [] }
</%args>
% $.IndexTable {{
%   $.IndexHead {{
      <% $.IndexHeadName("Layer") %>
      <% $.IndexHeadActions("Actions") %>
%   }}
%   $.IndexBody {{
%     for my $layer (@{$.layers}) {
%       $.IndexItem {{
%         $.IndexItemName("", "/admin/layer/".$layer->id) {{
            <% $layer->label | H %>
%         }}
%         $.IndexItemActions {{
            <% $.IndexItemAction(
                 0,
                 "/admin/layer/" . $layer->id . "/delete",
                 "minus-sign",
                 "Remove"
               ) %>
%         }}
%       }}
%     }
%   }}
% }}
<a href="<% $c->uri_for("/admin/layer/new") %>" class="btn btn-primary">
  New Layer
</a>
