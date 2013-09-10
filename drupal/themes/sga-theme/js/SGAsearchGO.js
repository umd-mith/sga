(function ($) { 

    $('#all-results').hide();

    var service = "http://ec2-107-22-87-255.compute-1.amazonaws.com/search";
    var options = $('#refine-results');
    var destination = $('#results-grid ul');

    SGAsearch.updateSearch(service, options, destination);

    $('#search-bar a').click( function() {
      $('#search-bar form').submit();
    });
    $('#search-bar form').submit( function (e) {
      e.preventDefault();
      $.bbq.removeState();
      $.bbq.pushState({q:$('#search-bar input').val(), f:'text'});
      $('#all-results').show();
      return false;
    });
})(jQuery);