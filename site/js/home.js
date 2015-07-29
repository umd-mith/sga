( function($) {

	$( '.menu-toggle' ).on( {
		click:function(e) {
			e.preventDefault();
			
			$(this).parent().toggleClass( 'toggled-on' );
		}
	} );

	$(window).load(function() {

		$("#slideshow").fadeIn("fast");
		$("#slideshow .slides img").show();
		$("slideshow .slides").fadeIn("slow");
		$("slideshow .slide-control").fadeIn("slow");
		$("#slide-nav").fadeIn("slow");

		$(".slides").cycle({ 
			fx:      	"fade", 
			speed:    	"slow",
			timeout: 	6000,
			random: 	0,
			nowrap: 	0,
			pause: 	  	1,
			prev:    	"#prev", 
	        next:    	"#next",
	        pager:  "#slide-nav",
			pagerAnchorBuilder: function(idx, slide) {
				return "#slide-nav li:eq(" + (idx) + ") a";
			},
			slideResize: true,
			containerResize: false,
			height: "auto",
			fit: 1,
			before: function(){
				$(this).parent().find(".slider-item.current").removeClass("current");
			},
			after: onAfter
		});
		
	});
	function onAfter(curr, next, opts, fwd) {
		var $ht = $(this).height();
		$(this).parent().height($ht);
		$(this).addClass("current");
	}

	$(window).load(function() {
		var $ht = $(".slider-item.current").height();
		$(".slides").height($ht);
	});

	$(window).resize(function() {
		var $ht = $(".slider-item.current").height();
		$(".slides").height($ht);
	});
	
} )(jQuery);
