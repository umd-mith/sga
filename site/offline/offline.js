const fs = require('fs')
const request = require('request').defaults({ encoding: null })
const async = require('async')
const xmldom = require('xmldom')

let clArgs = process.argv.slice(2);
if (clArgs.length === 0) {
  console.log('usage: offline.js PATH_TO_MANIFEST')
  process.exit(0);
}

let manifestPath = clArgs[0]
let iiifOxTable = {
  'ox-ms_abinger_c56': '53fd0f29-d482-46e1-aa9d-37829b49987d',
  'ox-ms_abinger_c57': '4d1b9912-7b6b-4276-900a-082f23f405fd',
  'ox-ms_abinger_c58': '05880098-0c28-4c85-acf1-25146976866e'
}
let viewerLocations = {
  'ox-ms_abinger_c56': 'oxford/ms_abinger/c56',
  'ox-ms_abinger_c57': 'oxford/ms_abinger/c57',
  'ox-ms_abinger_c58': 'oxford/ms_abinger/c58'
}

if (fs.existsSync(manifestPath)) {
    let manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    let msName = manifestPath.split('/').splice(-2,1)
    let mapping = {}

    function addToMap(uri, data) {
      if (!mapping.hasOwnProperty(uri)) {
        mapping[uri] = data
      }
    }

    // Get Oxford manifest
    let oxLoc = 'https://iiif.bodleian.ox.ac.uk/iiif/manifest/'+iiifOxTable[msName]+'.json'
    // Get IIIF Presentation manifest
    let p = new Promise((res, rej) => {
      request.get(oxLoc, function (error, response, body) {
        if (!error && response.statusCode == 200) {
          res(JSON.parse(body))
        } else rej()
      })
    }).then((oxJson) => {
      let promises = []

      let q = async.queue(function(qData, callback) {
        request(qData.imgLoc, function (error, response, body) {
          if (!error && response.statusCode === 200) {
            addToMap(qData.url, 'data:image/jpg;base64,' + new Buffer(body, 'binary').toString('base64'))
            callback(true)
          } else {
            console.log('Could not retrieve image:', error, response)
            callback(false)
          }
        })
      }, 10);

      console.log('Obtaining manifest resources...')
      manifest['@graph'].map(part => {
        // get every XML file
        if (part['@type']) {
          if (part['@type'] === 'oa:SpecificResource') {
            if (part.full.endsWith('.xml')){
              // Obtain TEI data
              // NB: This is usually to a symlink, see sga/site README
              let teiPath = '../tei/' + part.full.split('/tei/')[1]
              let tei = fs.readFileSync(teiPath, 'utf8')
              addToMap(part.full, tei)
            }
          }
        }
        // get every HTML file
        if (part['sc:motivatedBy']) {
          if (part['sc:motivatedBy']['@id'] === 'sga:reading') {
            // Obtain TEI data
            // NB: This is usually to a symlink and HTML files need to be generated separately, see sga/site README
            let htmlPath = '../tei/' + part.resource.split('/tei/')[1]
            let html = fs.readFileSync(htmlPath, 'utf8')
            addToMap(part.resource, html)
          }
        }
        // get every image at max available from Oxford

        if (part.format) {
          if (part.format === 'image/jp2') {
            // locate the same canvas on the oxford manifest
            let canvasId = manifest['@graph'].filter(x => x.resource === part["@id"])[0].on
            let canvasNum = manifest['@graph'].filter(x => x.canvases)[0].canvases.indexOf(canvasId)
            let imgLoc = oxJson.sequences[0].canvases[canvasNum].images[0].resource['@id']

            let p = new Promise((res, rej) => {
              q.push({imgLoc: imgLoc, url: part['@id']}, function (retrieved) {
                  if (retrieved) {
                    res()
                  } else {
                    rej()
                    process.exit(1)
                  }
              })
            })

            promises.push(p)
          }
        }
      })
      Promise.all(promises).then(()=>{

        console.log('Preparing HTML')

        // Read jekyll-generated Shared Canvas page

        let pageLoc = '../_site/sc/' + viewerLocations[msName] + '/index.html'
        if (fs.existsSync(pageLoc)) {
          let page = fs.readFileSync(pageLoc, 'utf8');
          let pageDom = new xmldom.DOMParser().parseFromString(page, 'text/html')
          let links = pageDom.getElementsByTagName('link')
          let scripts = pageDom.getElementsByTagName('script')
          let images = pageDom.getElementsByTagName('img')
          let head = pageDom.getElementsByTagName('head')[0]

          // Change data-manifest attribute to #local
          pageDom.getElementById("SGASharedCanvasViewer").setAttribute("data-manifest", '#local')

          // Adjust HTML components
          let search = pageDom.getElementById('search-form-block')
          search.parentNode.removeChild(search)

          let menu = pageDom.getElementById('main-navbar-collapse')
          menu.parentNode.removeChild(menu)

          // Incorporate images (HTML)
          for (var i=0, len = images.length; i != len; ++i) {
            if (images[i].getAttribute('src')) {
              let imgPath = '../_site' + images[i].getAttribute('src')
              let extension = imgPath.split('.').slice(-1)[0]
              extension = extension === 'svg' ? 'svg+xml' : extension
              let image = fs.readFileSync(imgPath)
              let imgString = new Buffer(image, 'binary').toString('base64')
              images[i].setAttribute('src', 'data:image/' + extension + ';base64,' + imgString)
            }
          }

          // Incorporate CSS
          for (i=0, len = links.length; i != len; ++i) {
            if (links[i].getAttribute('rel') == 'stylesheet') {
              let cssPath = '../_site' + links[i].getAttribute('href')
              let css = fs.readFileSync(cssPath, 'utf8');
              // Incorporate images
              let urls = css.match(/url\(.*?\)/g)
              if (urls) {
                for (let url of css.match(/url\(.*?\)/g)) {
                  if (url.includes('images/')) {
                    let imgPath = url.split('images/').slice(-1)[0].replace(/['"]?\)/, '')
                    let extension = imgPath.split('.').slice(-1)[0]
                    extension = extension === 'svg' ? 'svg+xml' : extension
                    if (fs.existsSync('../images/' + imgPath)) {
                      let image = fs.readFileSync('../images/' + imgPath)
                      let imgString = new Buffer(image, 'binary').toString('base64')
                      css = css.replace(url, 'url(data:image/' + extension + ';base64,' + imgString + ')')
                    }
                  } else if (url.includes('fonts/')) {
                    let fontPath = url.split('fonts/').slice(-1)[0].replace(/['"]?\)/, '')
                    let extension = fontPath.split('.').slice(-1)[0]
                    if (fs.existsSync('../fonts/' + fontPath)) {
                      let font = fs.readFileSync('../fonts/' + fontPath)
                      let fontString = new Buffer(font, 'binary').toString('base64')
                      css = css.replace(url, 'url(data:application/x-font-' + extension + ';charset=utf-8;base64,' + fontString + ')')
                    }
                  } else {
                    css = css.replace(url, '')
                  }
                }
              }
              let style = pageDom.createElement('style')
              style.appendChild(pageDom.createTextNode(css))
              links[i].parentNode.replaceChild(style, links[i])
            }
          }

          // Incorporate JS
          for (var i=0, len = scripts.length; i != len; ++i) {
            if (scripts[i].getAttribute('src')) {
              let jsPath = '../_site' + scripts[i].getAttribute('src')
              let js = fs.readFileSync(jsPath, 'utf8');
              let script = pageDom.createElement('script')
              script.setAttribute('type', 'text/javascript')
              script.appendChild(pageDom.createTextNode(js))
              scripts[i].parentNode.replaceChild(script, scripts[i])
            }
          }

          // Incorporate manifest and mapping
          let anchor = pageDom.getElementsByTagName('title')[0]
          let mappingContent = 'window.mapping = ' + JSON.stringify(mapping)
          let mappingScript = pageDom.createElement('script')
          mappingScript.setAttribute('type', 'text/javascript')
          mappingScript.appendChild(pageDom.createTextNode(mappingContent))
          head.insertBefore(mappingScript, anchor)

          let manifestContent = 'window.manifest = ' + JSON.stringify(manifest)
          let manifestScript = pageDom.createElement('script')
          manifestScript.setAttribute('type', 'text/javascript')
          manifestScript.appendChild(pageDom.createTextNode(manifestContent))
          head.insertBefore(manifestScript, anchor)

          fs.writeFile(msName+'.html', new xmldom.XMLSerializer().serializeToString(pageDom), function (err) {
              if (err) return console.log(err)
              console.log('Offline file created successfully.')
          })
        } else {
          console.log('Jekyll-generated viewer page not found; make sure to build site first')
          process.exit(1)
        }

      })
    })

} else {
  console.log('Manifest not found')
  process.exit(1)
}
