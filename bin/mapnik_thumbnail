#!/usr/bin/env node
'use strict'

// Node script to generate thumbnail image
// Use: ./mapnik_thumbnail width height out_path style_sheet_string
const fs = require('node:fs')
const mapnik = require('@mapnik/mapnik')

// Our templates use init rules, so set this.
process.env.PROJ_USE_PROJ4_INIT_RULES = 'YES';

mapnik.register_default_fonts()
mapnik.register_default_input_plugins()

const args = process.argv.slice(2)
const width = parseInt(args[0])
const height = parseInt(args[1])
const outputPath = args[2]
const stylesheet = args[3]
const map = new mapnik.Map(width, height)

map.fromString(stylesheet, function (err, res) {
  map.zoomAll()
  const im = new mapnik.Image(width, height)
  map.render(im, function (err, im) {
    im.encode("png", function (err, buffer) {
      fs.writeFile(outputPath, buffer, (err) => {
        if (err) console.log(err)
      })
    })
  })
})
