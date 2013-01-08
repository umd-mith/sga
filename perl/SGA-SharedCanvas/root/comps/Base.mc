<%augment wrap><!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=2.0">
    <title>Shared Canvas</title>
    <script src="<% $c->uri_for('/static/js/jquery.js') %>"></script>
    <script src="<% $c->uri_for('/static/js/jquery-ui-1.8.22.custom.min.js') %>"></script>
    <script src="<% $c->uri_for('/static/js/bootstrap.min.js') %>"></script>
    <link href="<% $c->uri_for('/static/css/bootstrap.min.css') %>" rel="stylesheet">
    <link href="<% $c->uri_for('/static/css/bootstrap-responsive.css') %>" rel="stylesheet">
    <link href="<% $c->uri_for('/static/css/overrides.css') %>" rel="stylesheet">
    <% $.headers() %>
    <style>
      body { padding-top: 60px; }
    </style>
  </head>
  <body>
    <div class="navbar navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
          <a class="brand" href="<% $c->uri_for("/") %>">Shared Canvas</a>
          <div class="nav-collapse">
            <ul class="nav">
              <% $.navLink("/", "Home") %>
              <% $.navLink("/admin", "Admin") %>
            </ul>
          </div>
        </div>
      </div>
    </div>
    <div class="container-fluid">
      <% inner() %>
    </div>
  </body>
</html>
</%augment>

<%method navLink($url, $text, $comp_path)>
% my $uri = $c -> uri_for($url);
% my $requri = substr($c -> request -> uri, 0, length($uri)+1);
% $comp_path ||= "/xxx";
% my $path = substr($m -> request_path, 0, length($comp_path)+1);
% if($requri eq $uri || $requri eq $uri."/" || $path eq $comp_path || $path eq $comp_path."/") {
<li class="active">
% }
% else {
<li>
% }
<a href="<% $uri %>"><% $text %></a>
</li>
</%method>
<%method headers></%method>
<%method form($title, $button, $cancel_url)>
<form method="POST" class="well form-horizontal">
  <fieldset>
    <legend><% $title %></legend>
    <% inner() %>
  </fieldset>
  <div class="form-actions">
    <input accesskey="S" class="btn btn-primary" name="commit" type="submit" value="<% $button %>">
    or <a href="<% $c -> uri_for($cancel_url) %>">Cancel</a>
  </div>
</form>
</%method>
