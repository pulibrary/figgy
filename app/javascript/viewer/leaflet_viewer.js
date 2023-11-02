/* global $ */
import L from 'leaflet'

export default class LeafletViewer {
  constructor (figgyId, tabManager) {
    this.figgyId = figgyId
    this.tabManager = tabManager
    this.bindResize()
  }

  async loadLeaflet () {
    // Check service URL
    return this.checkTileJson()
      .then(this.createLeaflet.bind(this))
      .then(() => this.bindTabs())
      .then(() => this.resize())
      .catch(() => {})
      .promise()
  }

  bindTabs () {
    this.tabManager.onTabSelect(() => this.focusMap())
  }

  bindResize () {
    window.addEventListener('resize', () => this.resize())
    this.resize()
  }

  resize () {
    if (this.map) {
      this.focusedMap = false
      this.map.invalidateSize()
    }
  }

  focusMap () {
    if (this.map && !this.focusedMap) {
      this.focusedMap = true
      this.map.invalidateSize()
      this.map.fitBounds([
        [this.tilejson.bounds[1], this.tilejson.bounds[0]],
        [this.tilejson.bounds[3], this.tilejson.bounds[2]]
      ])
    }
  }

  createLeaflet (tilejson) {
    if (tilejson.tiles === undefined) { return }

    document.getElementById('tab-container').style.display = 'block'
    document.getElementById('map-tab').style.display = 'block'
    let map = L.map('leaflet', {
      maxBounds: [[-100, -180], [100, 180]],
      touchZoom: false,
      scrollWheelZoom: false
    })

    L.tileLayer('https://cartodb-basemaps-b.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
      maxZoom: 18
    }).addTo(map)

    L.tileLayer(tilejson.tiles[0], {
      maxZoom: 18
    }).addTo(map)
    this.map = map
    this.tilejson = tilejson
  }

  checkTileJson () {
    return $.ajax(this.tileJsonUrl, { type: 'GET' })
  }

  get tileJsonUrl () {
    return `${this.tileMetadataRoot}/${this.figgyId}/tilejson`
  }

  get mapTab () {
    return document.getElementById('map-tab-content')
  }

  get tileMetadataRoot () {
    return this.mapTab.getAttribute('data-tilemetadata')
  }
}
