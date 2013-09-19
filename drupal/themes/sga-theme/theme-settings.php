<?php

/**
 * Implements hook_form_FORM_ID_alter().
 *
 * @param $form
 *   The form.
 * @param $form_state
 *   The form state.
 */
function sgarchive_form_system_theme_settings_alter(&$form, &$form_state) {
   
    $form['mtt_settings'] = array(
        '#type' => 'fieldset',
        '#title' => t('Corked Screwer Theme Settings'),
        '#collapsible' => FALSE,
        '#collapsed' => FALSE,
    );

    $form['mtt_settings']['highlighted'] = array(
        '#type' => 'fieldset',
        '#title' => t('Featured Content'),
        '#collapsible' => TRUE,
        '#collapsed' => FALSE,
    );

    $form['mtt_settings']['highlighted']['highlighted_display'] = array(
        '#type' => 'checkbox',
        '#title' => t('Show featured content'),
        '#description'   => t('Use the checkbox to enable or disable featured content.'),
        '#default_value' => theme_get_setting('highlighted_display','sgarchive'),
    );

    $form['mtt_settings']['breadcrumb'] = array(
        '#type' => 'fieldset',
        '#title' => t('Breadcrumb'),
        '#collapsible' => TRUE,
        '#collapsed' => FALSE,
    );

    $form['mtt_settings']['breadcrumb']['breadcrumb_display'] = array(
        '#type' => 'checkbox',
        '#title' => t('Show breadcrumb'),
        '#description'   => t('Use the checkbox to enable or disable breadcrumb.'),
        '#default_value' => theme_get_setting('breadcrumb_display','sgarchive'),
    );

    $form['mtt_settings']['breadcrumb']['breadcrumb_separator'] = array(
        '#type' => 'textfield',
        '#title' => t('Breadcrumb separator'),
        '#default_value' => theme_get_setting('breadcrumb_separator','sgarchive'),
        '#size'          => 5,
        '#maxlength'     => 10,
    );

    $form['mtt_settings']['slideshow'] = array(
        '#type' => 'fieldset',
        '#title' => t('Front Page Slideshow'),
        '#collapsible' => TRUE,
        '#collapsed' => FALSE,
    );

    $form['mtt_settings']['slideshow']['slideshow_display'] = array(
        '#type' => 'checkbox',
        '#title' => t('Show slideshow'),
        '#default_value' => theme_get_setting('slideshow_display','sgarchive'),
    );

    $form['mtt_settings']['slideshow']['slideshow_js'] = array(
        '#type' => 'checkbox',
        '#title' => t('Include slideshow javascript code'),
        '#default_value' => theme_get_setting('slideshow_js','sgarchive'),
    );

    $form['mtt_settings']['slideshow']['slideshow_effect'] = array(
    '#type' => 'select',
    '#title' => t('Effects'),
    '#description'   => t('From the drop-down menu, select the slideshow effect you prefer.'),
    '#default_value' => theme_get_setting('slideshow_effect','sgarchive'),
    '#options' => array(
        'blindX' => t('blindX'),
        'blindY' => t('blindY'),
        'blindZ' => t('blindZ'),
        'cover' => t('cover'),
        'curtainX' => t('curtainX'),
        'curtainY' => t('curtainY'),
        'fade' => t('fade'),
        'fadeZoom' => t('fadeZoom'),
        'growX' => t('growX'),
        'growY' => t('growY'),
        'scrollUp' => t('scrollUp'),
        'scrollDown' => t('scrollDown'),
        'scrollLeft' => t('scrollLeft'),
        'scrollRight' => t('scrollRight'),
        'scrollHorz' => t('scrollHorz'),
        'scrollVert' => t('scrollVert'),
        'shuffle' => t('shuffle'),
        'slideX' => t('slideX'),
        'slideY' => t('slideY'),
        'toss' => t('toss'),
        'turnUp' => t('turnUp'),
        'turnDown' => t('turnDown'),
        'turnLeft' => t('turnLeft'),
        'turnRight' => t('turnRight'),
        'uncover' => t('uncover'),
        'wipe' => t('wipe'),
        'zoom' => t('zoom'),
        ),
    );

    $form['mtt_settings']['slideshow']['slideshow_effect_time'] = array(
        '#type' => 'textfield',
        '#title' => t('Effect duration (sec)'),
        '#default_value' => theme_get_setting('slideshow_effect_time','sgarchive'),
    );

    $form['mtt_settings']['slideshow']['slideshow_randomize'] = array(
        '#type' => 'checkbox',
        '#title' => t('Randomize slideshow order'),
        '#default_value' => theme_get_setting('slideshow_randomize','sgarchive'),
    );

    $form['mtt_settings']['slideshow']['slideshow_wrap'] = array(
        '#type' => 'checkbox',
        '#title' => t('Prevent slideshow from wrapping'),
        '#default_value' => theme_get_setting('slideshow_wrap','sgarchive'),
    );

    $form['mtt_settings']['slideshow']['slideshow_pause'] = array(
        '#type' => 'checkbox',
        '#title' => t('Pause slideshow on hover'),
        '#default_value' => theme_get_setting('slideshow_pause','sgarchive'),
    );

    $form['mtt_settings']['support']['responsive'] = array(
        '#type' => 'fieldset',
        '#title' => t('Responsive'),
        '#collapsible' => TRUE,
        '#collapsed' => FALSE,
    );

    $form['mtt_settings']['support']['responsive']['responsive_meta'] = array(
        '#type' => 'checkbox',
        '#title' => t('Add meta tags to support responsive design on mobile devices.'),
        '#default_value' => theme_get_setting('responsive_meta','sgarchive'),
    );

    $form['mtt_settings']['support']['responsive']['responsive_respond'] = array(
        '#type' => 'checkbox',
        '#title' => t('Add Respond.js JavaScript to add basic CSS3 media query support to IE 6-8.'),
        '#default_value' => theme_get_setting('responsive_respond','sgarchive'),
        '#description'   => t('IE 6-8 require a JavaScript polyfill solution to add basic support of CSS3 media queries. Note that you should enable <strong>Aggregate and compress CSS files</strong> through <em>/admin/config/development/performance</em>.'),
    );
    
}