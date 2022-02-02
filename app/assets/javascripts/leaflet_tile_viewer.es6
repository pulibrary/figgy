export default class LeafletTileViewer {
  constructor ($element) {
    this.$url = $($element).data().url
    this.$element = $element
    this.initializeMap()
  }

  initializeMap () {
    let elementId = this.$element.attr('id')
    fetch(this.$url)
      .then(response => {
        if (!response.ok) {
          throw new Error('Unable to fetch tile.json document')
        }
        return response.json()
      })
      .then(tilejson => {
        let map = L.map(elementId, {
          maxBounds: [[-100, -180], [100, 180]],
          touchZoom: false,
          scrollWheelZoom: false
        }).fitBounds([
          [tilejson.bounds[1], tilejson.bounds[0]],
          [tilejson.bounds[3], tilejson.bounds[2]]
        ])

        L.tileLayer('https://cartodb-basemaps-b.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
          maxZoom: 18
        }).addTo(map)

        L.tileLayer(tilejson.tiles[0], {
          maxZoom: 18
        }).addTo(map)
      })
      .catch(error => {
        this.$element.hide()
        console.debug(error)
      })
  }
}
