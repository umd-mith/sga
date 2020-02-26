const fs = require('fs');

const rawdata = fs.readFileSync('02cddd3b-0383-41c6-9dfc-bee7f75a6553.json');
const manifest = JSON.parse(rawdata);
const teiDir = '../../data/tei/ox/ox-ms_abinger_d33/'
const teiDirList = fs.readdirSync(teiDir)

for (const [i, canvas] of manifest.sequences[0].canvases.entries()) {
  // Skipping the first two is specific to this example; adjust as needed.
  if (i > 1) {
    // Open TEI file
    const teiRawData = fs.readFileSync(teiDir + teiDirList[i-1]) // -2 because we're skipping two images from the manifest. Adjust as needed.
    const teiData = teiRawData.toString()
    let output = teiData.replace(/lrx="[^"]+"/, `lrx="${canvas.width}"`)
    output = output.replace(/lry="[^"]+"/, `lry="${canvas.height}"`)
    const imageURL = canvas['@id'].replace('/canvas/', '/image/').replace(/\.json$/, '')
    // This assumes there's no <graphic> element, which may not always be the case. Adjust as needed
    output = output.replace(/(mith:folio="[^"]+">)/, `$1\n<graphic url="${imageURL}"/>`)
    fs.writeFileSync(teiDir + teiDirList[i-1], output) // adjust -2
  }
}