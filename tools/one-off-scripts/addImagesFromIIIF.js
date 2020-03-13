const fs = require('fs');

const rawdata = fs.readFileSync('cb962b5e-3356-4d8c-aa9f-03a616095690.json');
const manifest = JSON.parse(rawdata);
const teiDir = '../../data/tei/ox/ox-ms_shelley_e3/'
const teiDirList = fs.readdirSync(teiDir)


for (const [i, canvas] of manifest.sequences[0].canvases.entries()) {
  // Skipping the first two is specific to this example; adjust as needed.
  if (i > 5) {
    // Open TEI file
    try {
      const teiRawData = fs.readFileSync(teiDir + teiDirList[i-6]) // -2 because we're skipping two images from the manifest. Adjust as needed.
      const teiData = teiRawData.toString()
      let output = teiData.replace(/lrx="[^"]+"/, `lrx="${canvas.width}"`)
      output = output.replace(/lry="[^"]+"/, `lry="${canvas.height}"`)
      const imageURL = canvas['@id'].replace('/canvas/', '/image/').replace(/\.json$/, '')
      // This assumes there's no <graphic> element, which may not always be the case. Adjust as needed
      // output = output.replace(/(mith:folio="[^"]+">)/, `$1\n<graphic url="${imageURL}"/>`)
      output = output.replace(/<graphic url="[^"]+"/, `<graphic url="${imageURL}"`)
      fs.writeFileSync(teiDir + teiDirList[i-6], output) // adjust -2
    } catch (error) {
      console.log("couldn't find a file" )
    }
    
  }
}