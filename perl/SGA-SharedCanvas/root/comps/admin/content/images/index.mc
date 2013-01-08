<%args>
$.images => sub { [] }
</%args>
% $.IndexTable {{
%   $.IndexHead {{
      <% $.IndexHeadName("Image") %>
%   }}
%   $.IndexBody {{
%     for my $image (@{$.images}) {
%       $.IndexItem {{
%         $.IndexItemName("", "/admin/image/".$image->id) {{
            <% $image->label %>
%         }}
%       }}
%     }
%   }}
% }}
<a href="<% $c->uri_for("/admin/image/new") %>" class="btn btn-primary">
  New Image
</a>
