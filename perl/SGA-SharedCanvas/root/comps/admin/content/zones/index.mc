<%args>
$.zones => sub { [] }
</%args>
% $.IndexTable {{
%   $.IndexHead {{
      <% $.IndexHeadName("Zone") %>
%   }}
%   $.IndexBody {{
%     for my $zone (@{$.zones}) {
%       $.IndexItem {{
%         $.IndexItemName("", "/admin/zone/".$zone->id) {{
            <% $zone->label %>
%         }}
%       }}
%     }
%   }}
% }}
<a href="<% $c->uri_for("/admin/zone/new") %>" class="btn btn-primary">
  New Zone
</a>
