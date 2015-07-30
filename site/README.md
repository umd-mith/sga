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
```
You can serve the site locally with:

```
$ jekyll serve
```

## Getting manifests and TEI data to work

But to have a fully functional website:

* symlink or copy `../data/tei/` to `tei`
* use [Unbind](github.com/umd-mith/unbind) to generate our Shared Canvas manifests and place them in `/manifests/`
* use [sg-readingTEI](https://github.com/umd-mith/sg-readingTEI) to generate reading views of the TEI and place them in `../data/tei/readingTEI/html`
