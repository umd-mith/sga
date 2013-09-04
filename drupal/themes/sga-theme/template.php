<?php
/** 
* Override or insert variables into the html template. 
*/ 
function sgarchive_preprocess_html(&$variables) {
	drupal_add_css(path_to_theme() . '/css/style.css', array('group' => CSS_THEME, 'type' => 'file', 'preprocess' => FALSE));
	if (!theme_get_setting('responsive_respond','sgarchive')):
	drupal_add_css(path_to_theme() . '/css/basic-layout.css', array('group' => CSS_THEME, 'browsers' => array('IE' => '(lte IE 8)&(!IEMobile)', '!IE' => FALSE), 'preprocess' => FALSE));
	endif;
	drupal_add_css(path_to_theme() . '/css/ie.css', array('group' => CSS_THEME, 'browsers' => array('!IE' => FALSE), 'preprocess' => FALSE));

	drupal_add_css('//netdna.bootstrapcdn.com/bootstrap/3.0.0-rc1/css/bootstrap.min.css', array('group' => CSS_THEME, 'type' => 'file', 'preprocess' => FALSE, 'weight' => '-1000'));
	drupal_add_css('//netdna.bootstrapcdn.com/font-awesome/3.2.1/css/font-awesome.css', array('group' => CSS_THEME, 'type' => 'file', 'preprocess' => FALSE, 'weight' => '-1000'));

	drupal_add_js('http://code.jquery.com/ui/1.9.2/jquery-ui.min.js');
	drupal_add_js('//netdna.bootstrapcdn.com/bootstrap/3.0.0-rc1/js/bootstrap.min.js');

	drupal_add_js(path_to_theme() . '/js/jquery.ba-bbq.min.js');

	$variables['bottom_scripts'] = drupal_get_js('bottom_scripts');
}

// drupal_add_js('jQuery(document).ready(function ($) { 	
	
// 	$("#collapse-one").collapse("hide");
	
// 	$(function() {
// 		$( "#slider-vertical" ).slider({
// 			orientation: "vertical",
// 			range: "min",
// 			min: 0,
// 			max: 100,
// 			value: 1,
// 			slide: function( event, ui ) {
// 			$( "#page-location" ).val( ui.value );
// 			}
// 		});
// 		$( "#page-location" ).val( $( "#slider-vertical" ).slider( "value" ) );
// 	});
	

// });', array('type' => 'inline', 'scope' => 'header', 'weight' => 4)
	
// );

/**
 * Add javascript files for jquery slideshow.
 */
if (theme_get_setting('slideshow_js','sgarchive')):

	drupal_add_js(drupal_get_path('theme', 'sgarchive') . '/js/jquery.cycle.all.js');
	
	//Initialize slideshow using theme settings
	$effect=theme_get_setting('slideshow_effect','sgarchive');
	$effect_time=theme_get_setting('slideshow_effect_time','sgarchive')*1000;
	$slideshow_randomize=theme_get_setting('slideshow_randomize','sgarchive');
	$slideshow_wrap=theme_get_setting('slideshow_wrap','sgarchive');
	$slideshow_pause=theme_get_setting('slideshow_pause','sgarchive');
	
	drupal_add_js('jQuery(document).ready(function($) {
	
		$(window).load(function() {

			$("#slideshow").fadeIn("fast");
			$("#slideshow .slides img").show();
			$("slideshow .slides").fadeIn("slow");
			$("slideshow .slide-control").fadeIn("slow");
			$("#slide-nav").fadeIn("slow");
		
			$(".slides").cycle({ 
				fx:      	"'.$effect.'", 
				speed:    	"slow",
	    		timeout: 	'.$effect_time.',
	    		random: 	'.$slideshow_randomize.',
	    		nowrap: 	'.$slideshow_wrap.',
	    		pause: 	  	'.$slideshow_pause.',
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

	});',
	array('type' => 'inline', 'scope' => 'footer', 'weight' => 5)
	);

endif;

/**
 * Return a themed breadcrumb trail.
 *
 * @param $breadcrumb
 *   An array containing the breadcrumb links.
 * @return
 *   A string containing the breadcrumb output.
 */
function sgarchive_breadcrumb($variables){
	$breadcrumb = $variables['breadcrumb'];
	$breadcrumb_separator=theme_get_setting('breadcrumb_separator','sgarchive');

	if (!empty($breadcrumb)) {
		$breadcrumb[] = drupal_get_title();
		return '<div id="breadcrumb">' . implode(' <span class="breadcrumb-separator">' . $breadcrumb_separator . '</span>', $breadcrumb) . '</div>';
	}

}

/**
 * Page alter.
 */
function sgarchive_page_alter($page) {

	if (theme_get_setting('responsive_meta','sgarchive')):
		$mobileoptimized = array(
			'#type' => 'html_tag',
			'#tag' => 'meta',
			'#attributes' => array(
			'name' =>  'MobileOptimized',
			'content' =>  'width'
			)
		);

		$handheldfriendly = array(
			'#type' => 'html_tag',
			'#tag' => 'meta',
			'#attributes' => array(
			'name' =>  'HandheldFriendly',
			'content' =>  'true'
			)
		);

		$viewport = array(
			'#type' => 'html_tag',
			'#tag' => 'meta',
			'#attributes' => array(
			'name' =>  'viewport',
			'content' =>  'width=device-width, initial-scale=1'
			)
		);

		drupal_add_html_head($mobileoptimized, 'MobileOptimized');
		drupal_add_html_head($handheldfriendly, 'HandheldFriendly');
		drupal_add_html_head($viewport, 'viewport');
	endif;
}


?>
