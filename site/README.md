# Site

Jekyll static site for shelleygodwinarchive.org.

## Components

The `components` directory hosts three JavaScript Backbone applications:

* SGAsearch: a client to our solr search server
* SGAtoc: an one-page app to browse through one or more table of contents of the archive's items
* SGAviewer: a one-page app to display our flavor of Shared Canvas manifests

## Installation

Requirements:

* Jekyll ^2.5.3
* npm

To build:

```
$ npm install
$ npm build
$ jekyll build
```
You can serve the site locally with:

```
$ jekyll serve
```

## Getting manifests and TEI data to work

The manifests `manifests/ox/ox-frankenstein_notebook_a/Manifest.json` and `manifests/ox/ox-frankenstein_notebook_a/Manifest-index.json` are provided as example. 

But to have a fully functional website:

* use [Unbind](github.com/umd-mith/unbind) to generate our Shared Canvas manifests and place them in `/manifests/`
* symlink or copy `../data/tei/` to `tei`
* use [sg-readingTEI](https://github.com/umd-mith/sg-readingTEI) to generate reading views of the TEI and place them in `../data/tei/readingTEI/html`
