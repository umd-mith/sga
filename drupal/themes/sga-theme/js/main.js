( function($) {
	/*var nav = $( '#main-menu-inside' ), button, menu;
	if ( ! nav )
		return;

	button = nav.find( '.menu-toggle' );
	if ( ! button )
		return;

	// Hide button if menu is missing or empty.
	menu = nav.find( '#menu' );
	if ( ! menu || ! menu.children().length ) {
		button.hide();
		return;
	}
	*/

	$( '.menu-toggle' ).on( {
		click:function(e) {
			e.preventDefault();
			
			$(this).parent().toggleClass( 'toggled-on' );
		}
	} );
} )(jQuery);
