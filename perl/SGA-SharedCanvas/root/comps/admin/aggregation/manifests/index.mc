<%args>
$.manifests => sub { [] }
</%args>
% $.IndexTable {{
%   $.IndexHead {{
      <% $.IndexHeadName("Manifest") %>
      <% $.IndexHeadActions("Actions") %>
%   }}
%   $.IndexBody {{
%     for my $manifest (@{$.manifests}) {
%       $.IndexItem {{
%         $.IndexItemName("", "/admin/manifest/".$manifest->id) {{
            <% $manifest->label %>
%         }}
%         $.IndexItemActions {{
            <% $.IndexItemAction(
                 0,
                 "/m/" . $manifest->id,
                 "play",
                 "Play"
               ) %>
            <% $.IndexItemAction(
                 0,
                 "/admin/manifest/" . $manifest->id . "/delete",
                 "minus-sign",
                 "Remove"
               ) %>
%         }}
%       }}
%     }
%   }}
% }}
<a href="<% $c->uri_for("/admin/manifest/new") %>" class="btn btn-primary">
  New Manifest
</a>
