<!-- <div>
<?php
    print '<pre>';
    $manifest = field_get_items('node',$node, 'field_manifest');
    $m = $manifest[0]['value'];

    $body = field_get_items('node',$node, 'body');
    $b = $body[0]['value'];

    $set_m = 'data-manifest="' . $m . '"';

    $new_b = preg_replace('/\[manifest\]/', $set_m, $b);

    //print $b;

    $body[0]['value'] = $new_b;

    // manifests/Manifest-jp2.json

    print '</pre>';
?>
</div> -->

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

