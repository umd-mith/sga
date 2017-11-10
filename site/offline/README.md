# Offline S-GA

This is experimental code to create offline copies of S-GA contents based on Jekyll-generate pages and Shared Canvas manifests.

## Compiled HTML

`node offline.js [PATH_TO_MANIFEST]`

This will generate a compiled HTML version of the manuscript modeled by the Shared Canvas manifest (e.g. the first Frankenstein manuscript MS. Abinger C.56). It downloads images from Oxford's IIIF servers.

**Warning:** the resulting file will be very large.

## Zipped version

`node offlineZip.js [PATH_TO_MANIFEST]`

This will gather resources related to the manuscript modeled by the Shared Canvas manifest; alter the manifest to point to local resources and zip it all up. **Important:** the script assumes that full images in jpeg format are available locally under `images`. These are not publicly available, but can be derived from Oxford IIIF servers.
