(function ($, Backbone) { 

    Backbone.history.start();

    $('#all-results').hide();

    // var service = "http://localhost:5000/search";
    var service = "http://54.166.24.46/search";
    var options = $('#refine-results');
    var destination = $('#results-grid ul');

    SGAsearch.updateSearch(service, options, destination);

    $('#search-bar a').click( function() {
      $('#search-bar form').submit();
    });
    $('#search-bar form').submit( function (e) {
      e.preventDefault();
      /* We reset manually all fields in one go: using removeState() causes
         a troublesome extra hashchange */

      hash = "#q=" + $('#search-bar input').val() + "&f=text"
      Backbone.history.navigate(hash)

      return false;
    });
})(jQuery, Backbone);