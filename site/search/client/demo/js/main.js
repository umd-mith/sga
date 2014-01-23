(function ($) { 

    $('#all-results').hide();

    var service = "http://localhost:5000/search";
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

      p = $.bbq.getState('p');
      nb = $.bbq.getState('nb');

      states = {q:  $('#search-bar input').val(), f:  'text'}
      if (p !== undefined) states.p = '';
      if (nb !== undefined) states.nb = '';

      $.bbq.pushState(states);
      return false;
    });
})(jQuery);