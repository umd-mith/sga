<?php 

    $path = drupal_get_path('theme', 'sgarchive');
    drupal_add_css($path . '/css/sc/overrides.css');
    drupal_add_css($path . '/css/sc/polymaps.css');
    drupal_add_css($path . '/css/sc/prettify.css');
    drupal_add_css($path . '/css/sc/shared-canvas.css');
    drupal_add_css($path . '/css/sc/jquery-ui.css');
    drupal_add_css($path . '/css/sc/reset.css');
    drupal_add_js($path . '/js/sc/modernizr-2.6.2.min.js');
    drupal_add_js($path . '/js/sc/jquery.svg.min.js');
    drupal_add_js($path . '/js/sc/jquery.svgdom.min.js');
    drupal_add_js($path . '/js/jquery.ba-bbq.min.js');
    drupal_add_js($path . '/js/sc/navigation.js');
    drupal_add_js($path . '/js/sc/jquery-ui-1.10.3.js');
    drupal_add_js($path . '/js/sc/polymaps.min.js');
    drupal_add_js($path . '/js/sc/adoratio.js');
    drupal_add_js($path . '/js/sc/mithgrid.min.js');
    drupal_add_js($path . '/js/sc/q.min.js');
    drupal_add_js($path . '/js/sc/prettify.js');
    drupal_add_js($path . '/js/sc/shared-canvas.js');
    drupal_add_js($path . '/js/sc/plugins.js', array('scope' => 'bottom_scripts', 'weight' => -1, 'preprocess' => FALSE));
    drupal_add_js($path . '/js/sc/main.js', array('scope' => 'bottom_scripts', 'weight' => -1, 'preprocess' => FALSE));

?>

<div id="node-<?php print $node->nid; ?>" class="<?php print $classes; ?>"<?php print $attributes; ?>>
	<?php print render($title_prefix); ?>
    <?php if (!$page): ?>
    <h2<?php print $title_attributes; ?>><a href="<?php print $node_url; ?>"><?php print $title; ?></a></h2>
    <?php endif; ?>
    <?php print render($title_suffix); ?>

    <div class="content"<?php print $content_attributes; ?>>

        <?php
            // We hide the comments and links now so that we can render them later.
            hide($content['comments']);
            hide($content['links']);
            print render($content['field_image']); 
        ?>
       
        <?php if ($display_submitted): ?>
        <div class="node-info"><span class="user"></span> <?php print $name ?> <span class="calendar"></span> <?php print $date; ?></div>
        <?php endif; ?>
       
        <?php print render($content); ?>

    </div>

    <div class="node-meta">
        
        <?php if(module_exists('comment') && ($node->comment == COMMENT_NODE_OPEN)) { ?>
        <div class="comments-count"><span class="comments"><?php print $comment_count; ?></span><a href="<?php print $node_url; ?>">comments</a></div>
        <?php } ;?>

        <?php  print render($content['links']); ?>
        
        <?php print render($content['field_tags']); ?>

        <?php $node_author = user_load($uid); ?>
        
		<?php if ($page): ?>
        <?php if($user_picture || $node_author->signature): ?>
        <div class="author-signature clearfix">
			<?php print $user_picture; ?>
            
			<?php if($node_author->signature): ?>
            <h5>About the author</h5>
            <?php print $node_author->signature; ?>
            </div> 
            <?php endif; ?>    
        <?php endif; ?>	
        <?php endif; ?>

        <?php print render($content['comments']); ?>
        
    </div>

</div>

