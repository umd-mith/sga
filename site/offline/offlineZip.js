const fs = require('fs')
const request = require('request').defaults({ encoding: null })
const ncp = require('ncp').ncp
const archiver = require('archiver')
const xmldom = require('xmldom')
const rimraf = require('rimraf')

let clArgs = process.argv.slice(2);
if (clArgs.length === 0) {
  console.log('usage: offlineZip.js PATH_TO_MANIFEST')
  process.exit(0);
}

let manifestPath = clArgs[0]
let viewerLocations = {
  'ox-ms_abinger_c56': 'oxford/ms_abinger/c56',
  'ox-ms_abinger_c57': 'oxford/ms_abinger/c57',
  'ox-ms_abinger_c58': 'oxford/ms_abinger/c58'
}

if (fs.existsSync(manifestPath)) {
  let promises = []
  let manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  let msName = manifestPath.split('/').splice(-2,1)[0]
  let newTeiPath = msName+"/tei"
  let newReadingTeiPath = msName+"/readingTei"
  let newImagesPath = msName+"/images"
  // create dir with ms name
  if (!fs.existsSync(msName)){
    fs.mkdirSync(msName)
  }
  if (!fs.existsSync(newTeiPath)){
    fs.mkdirSync(newTeiPath)
  }
  if (!fs.existsSync(newReadingTeiPath)){
    fs.mkdirSync(newReadingTeiPath)
  }
  if (!fs.existsSync(newImagesPath)){
    fs.mkdirSync(newImagesPath)
  }

  // update manifest to use local paths
  console.log('Copying manifest resources...')
  manifest['@graph'].forEach(part => {
    // get every XML file
    if (part['@type']) {
      if (part['@type'] === 'oa:SpecificResource') {
        if (part.full.endsWith('.xml')){
          // Obtain TEI data
          // NB: This is usually to a symlink, see sga/site README
          let teiPath = '../tei/' + part.full.split('/tei/')[1]
          let newLoc = newTeiPath+'/'+part.full.split('/').splice(-1)[0]
          // Update manifest
          part.full = 'tei/'+part.full.split('/').splice(-1)[0]
          // Copy to new location
          let p = new Promise((res, rej) => {
            let r = fs.createReadStream(teiPath, 'utf8')
            let w = fs.createWriteStream(newLoc)
            w.on('close', () => res())
            r.pipe(w)
          })
          promises.push(p)
        }
      }
    }
    // get every HTML file
    if (part['sc:motivatedBy']) {
      if (part['sc:motivatedBy']['@id'] === 'sga:reading') {
        // Obtain TEI data
        // NB: This is usually to a symlink and HTML files need to be generated separately, see sga/site README
        let htmlPath = '../tei/' + part.resource.split('/tei/')[1]
        let newLoc = newReadingTeiPath+'/'+part.resource.split('/').splice(-1)[0]
        // Update manifest
        part.resource = 'readingTei/'+part.resource.split('/').splice(-1)[0]
        // Copy to new location
        let p = new Promise((res, rej) => {
          let r = fs.createReadStream(htmlPath, 'utf8')
          let w = fs.createWriteStream(newLoc)
          w.on('close', () => res())
          r.pipe(w)
        })
        promises.push(p)
      }
    }
    // get every image
    // NB images are assumed to be available locally at ./images
    if (part.format) {
      if (part.format === 'image/jp2') {
        let imgPath = 'images' + part['@id'].split('/images/ox')[1].split('.jp2')[0]+'.jpg'
        let imgName = part['@id'].split('/').splice(-1)[0].split('.jp2')[0]+'.jpg'
        let newLoc = newImagesPath+'/'+imgName
        // Update manifest
        part['@id'] = 'images/'+imgName
        part.service = './'
        // Copy to new location
        let p = new Promise((res, rej) => {
          let r = fs.createReadStream(imgPath)
          let w = fs.createWriteStream(newLoc)
          w.on('close', () => res())
          r.pipe(w)
        })
        promises.push(p)
      }
    }
    // Update resource ids on manifest
    if (part.resource) {
      if (part.resource.endsWith('.jp2')) {
        let imgName = part.resource.split('/').splice(-1)[0].split('.jp2')[0]+'.jpg'
        part.resource = 'images/'+imgName
      }
      if (part.resource.endsWith('.xml')) {
        part.resource = 'tei/' + part.resource.split('/').splice(-1)[0]
      }
    }
  })

  console.log('Writing Shared Canvas Manifest')

  // Save manifest
  fs.writeFile(msName+'/Manifest.jsonld', JSON.stringify(manifest), function (err) {
      if (err) return console.log(err)
  })

  console.log('Copying site resources')
  ncp('../_site/css', msName+'/css', function (err) {
   if (err) {
     return console.error(err);
   }
  })
  ncp('../_site/js', msName+'/js', function (err) {
   if (err) {
     return console.error(err);
   }
  })
  ncp('../_site/fonts', msName+'/fonts', function (err) {
   if (err) {
     return console.error(err);
   }
  })
  ncp('../_site/images', msName+'/images', function (err) {
   if (err) {
     return console.error(err);
   }
  })

  // Read jekyll-generated Shared Canvas page
  let pageLoc = '../_site/sc/' + viewerLocations[msName] + '/index.html'

  if (fs.existsSync(pageLoc)) {
    let page = fs.readFileSync(pageLoc, 'utf8');
    let pageDom = new xmldom.DOMParser().parseFromString(page, 'text/html')
    let head = pageDom.getElementsByTagName('head')[0]

    // Change data-manifest attribute
    pageDom.getElementById("SGASharedCanvasViewer").setAttribute("data-manifest", 'Manifest.jsonld')

    // Adjust HTML components
    let search = pageDom.getElementById('search-form-block')
    search.parentNode.removeChild(search)

    let menu = pageDom.getElementById('main-navbar-collapse')
    menu.parentNode.removeChild(menu)

    let scripts = pageDom.getElementsByTagName('script')

    for (var i=0, len = scripts.length; i != len; ++i) {
      if (scripts[i].textContent.includes("google-analytics.com")) {
          scripts[i].parentNode.removeChild(scripts[i])
      }
    }

    fs.writeFile(msName+'/index.html', new xmldom.XMLSerializer().serializeToString(pageDom), function (err) {
        if (err) return console.log(err)
    })

  } else {
    console.log('Jekyll-generated viewer page not found; make sure to build site first')
    process.exit(1)
  }

  // Once all files are copied, zip!
  Promise.all(promises).then(() => {
    console.log("Done! Zipping...")
    let output = fs.createWriteStream(msName+'.zip');
    let archive = archiver('zip', {
      zlib: { level: 9 }
    })
    archive.pipe(output)
    archive.directory(msName, false);
    archive.finalize()

    output.on('close', function() {
      console.log('Cleaning up...')
      rimraf(msName, function () { console.log('All done.'); });
    });

  })

} else {
  console.log('Manifest not found')
  process.exit(1)
}
