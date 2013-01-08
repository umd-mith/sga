<%args>
$.canvas
</%args>
<%method form($title, $button)>
<form method="POST" class="well form-horizontal">
  <fieldset>
    <legend><% $title %></legend>
  </fieldset>
  <div class="form-actions">
    <input accesskey="S" class="btn btn-primary" name="commit" type="submit" value="<% $button | H %>">
    or <a href="<% $c -> uri_for("/admin/zone/") %>">Cancel</a>
  </div>
</form>
</%method>
