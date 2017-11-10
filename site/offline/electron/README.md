# S-GA Offline Electron version

This is a minimal Electron application that wraps offline versions of S-GA manifests generated with `../offlineZip.js` and a few modifications:

* Place assets (CSS, JS, site images) at root level but keep MS images within a manuscript's directory
* Add this to every page to make sure JQuery works:

```
<script>if (typeof module === 'object') {window.module = module; module = undefined;}</script>
```

* Optionally add a button to go back to the index (the main logo page already does that, though)

## To use

`npm start`

## To compil

`npm dist`
