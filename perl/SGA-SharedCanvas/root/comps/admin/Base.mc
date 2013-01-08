<%args>
$.missing => sub { [] }
$.invalid => sub { [] }
$.form_data => sub { +{} }
</%args>

<%augment wrap>
  <% $.navigation %>
  <div class="row-fluid">
    <div class="span12">
      <% inner() %>
    </div>
  </div>
  <script>
    $(function() {
      $(".invalid").each(function(idx, el) {
        $(el).parent().addClass("error");
      });
    });
  </script>
</%augment>

<%method navigation>
  <div class="row-fluid">
    <div class="span12">
      <% $.nav_tabs() %>
      <% $.sub_nav_tabs() %>
    </div>
  </div>
</%method>

<%method nav_tabs>
  <ul class="nav nav-pills">
    <% $.navLink("/admin/manifest", "Aggregation", "/admin/aggregation") %>
    <% $.navLink("/admin/image_annotation", "Annotation", "/admin/annotation") %>
    <% $.navLink("/admin/canvas", "Content", "/admin/content") %>
  </ul>
</%method>

<%method sub_nav_tabs>
  <ul class="nav nav-tabs">
    <% inner() %>
  </ul>
</%method>

% # Now we have a series of blocks that we can use to create the admin
% # pages

<%filter IndexTable($notCondensed)>
<table class="table table-bordered table-striped<% !$notCondensed ? ' table-condensed' : '' %>"
       style="width: 100%">
  <% $yield->() %>
</table>
</%filter>

<%filter IndexHead>
<thead>
  <tr><% $yield->() %></tr>
</thead>
</%filter>

<%method IndexHeadName ($title)>
<th class="name" style="width: 100%"><% $title %></th>
</%method>

<%method IndexHeadCol ($class, $title)>
<th class="<% $class %>"><% $title %></th>
</%method>

<%method IndexHeadStatus ($title)>
<th class="status" style="min-width: 8em;"><% $title %></th>
</%method>

<%method IndexHeadActions ($title)>
<th class="actions" style="padding-left: 15px; min-width: 18em;"><% $title %></th>
</%method>

<%filter IndexBody>
<tbody>
  <% $yield->() %>
</tbody>
</%filter>

<%filter IndexItem ($classes)>
<tr class="<% $classes %>"><% $yield->() %></tr>
</%filter>

<%filter IndexItemName ($img, $link)>
<td class="name">
% if($link) {
  <a href="<% $c->uri_for($link) %>">
% }
%   if($img) {
    <img src="<% $c -> uri_for("/static/images/admin/$img.png") %>" />
%   }
    <% $yield->() %>
% if($link) {
  </a>
% }
</%filter>

<%filter IndexItemStatus>
<td class="status"><% $yield->() %></td>
</%filter>

<%filter IndexItemCol ($class)>
<td class="<% $class %>"><% $yield->() %></td>
</%filter>

<%filter IndexItemActions>
<td class="actions"><% $yield->() %></td>
</%filter>

<%method IndexItemAction ($disabled, $href, $icon, $title)>
% if($disabled) {
  <span class="btn btn-small disabled">
% }
% else {
  <a href="<% $c->uri_for($href) %>" class="btn btn-small">
% }
% if($icon) {
  <i class="icon icon-<% $icon %>"></i>
% }
<% $title %>
% if($disabled) {
  </span>
% }
% else {
  </a>
% }
</%method>

<%method ifEqual($a, $b, $text)>
% if(defined($a) && defined($b) && $a eq $b) {
<% $text %>
% }
</%method>

<%method formClasses($field)>
% if(grep { $_ eq $field } @{$.missing}) {
 error
% }
% if(grep { $_ eq $field } @{$.invalid}) {
 error
% }
</%method>
