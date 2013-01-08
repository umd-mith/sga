<%args>
$.sequences => sub { [] }
</%args>
% $.IndexTable {{
%   $.IndexHead {{
      <% $.IndexHeadName("Sequence") %>
      <% $.IndexHeadActions("Actions") %>
%   }}
%   $.IndexBody {{
%     for my $sequence (@{$.sequences}) {
%       $.IndexItem {{
%         $.IndexItemName("", "/admin/sequence/".$sequence->id) {{
            <% $sequence->label %>
%         }}
%         $.IndexItemActions {{
            <% $.IndexItemAction(
                 0,
                 "/admin/sequence/".$sequence->id."/remove",
                 "minus-sign",
                 "Remove"
               ) %>
            <% $.IndexItemAction(
                 0,
                 "/admin/sequence/".$sequence->id."/copy",
                 "plus-sign",
                 "Copy"
               ) %>
%         }}
%       }}
%     }
%   }}
% }}
<a href="<% $c->uri_for("/admin/sequence/new") %>" class="btn btn-primary">
  New Sequence
</a>
