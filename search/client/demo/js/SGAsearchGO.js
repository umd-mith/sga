(function ($) { 
    var service = "http://localhost:5000/search";
    var options = $('#refine-results');
    var destination = $('#results-grid ul');

    SGAsearch.updateSearch(service, options, destination);

    $('#search-bar a').click( function() {
      $('#search-bar form').submit();
    });
    $('#search-bar form').submit( function (e) {
      e.preventDefault();
      $.bbq.pushState({q:$('#search-bar input').val(), f:'text'});
      return false;
    });
})(jQuery);