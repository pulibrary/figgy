export default class BoundingBoxSelector {
  constructor(element) {
    this.coverage = element.data().coverage
    this.readOnly = element.data().readOnly
    this.inputElement = document.getElementById(element.data().inputId)
    this.north = document.getElementById("bbox-north")
    this.east = document.getElementById("bbox-east")
    this.south = document.getElementById("bbox-south")
    this.west = document.getElementById("bbox-west")
    this.clear = document.getElementById("bbox-clear")
    this.defaultBounds = L.latLngBounds([[-50, -100], [72, 100]])
    this.initialize_map()
  }

  initialize_map() {
    let initialBounds;
    let that = this;
    if (!this.coverage && this.inputElement ) {
      this.coverage = this.inputElement.value
    }

    if ((this.coverage) && (this.coverage.length !== 0)) {
      initialBounds = this.coverageToBounds(this.coverage)
      this.updateBboxInputs(initialBounds)
    } else {
      initialBounds = this.defaultBounds
    };

    let map = L.map('bbox', {
      maxBounds: [[-100, -180], [100, 180]],
      touchZoom: false,
      scrollWheelZoom: false
    }).fitBounds(initialBounds)

    L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
      maxZoom: 18
    }).addTo(map)
    L.Control.geocoder({ position: 'topleft' }).addTo(map)

    if (this.readOnly) {
      new L.Rectangle(initialBounds, { color: 'blue', weight: 2, opacity: 0.9 }).addTo(map)
    } else {
      this.boundingBox = new L.BoundingBox({ bounds: initialBounds,
                                     buttonPosition: 'topright', }).addTo(map)

      this.boundingBox.on('change', function() {
        that.inputElement.value = that.boundsToCoverage(this.getBounds())
        that.updateBboxInputs(this.getBounds())
      })

      // Enable Clear Coverage button
      this.clear.style.display = 'block'
      this.clear.addEventListener('click', () => {
        this.boundingBox.setBounds(this.defaultBounds)
        map.fitBounds(this.defaultBounds)
        this.north.value = null
        this.east.value = null
        this.south.value = null
        this.west.value = null
        this.inputElement.value = null
      })

      // Enable editing of bbox inputs
      this.north.readOnly = false
      this.east.readOnly = false
      this.south.readOnly = false
      this.west.readOnly = false

      // Update bounding box when value in inputs are changed
      this.north.addEventListener('change', () => { this.setNewBoundsFromInputs() });
      this.east.addEventListener('change', () => { this.setNewBoundsFromInputs() });
      this.south.addEventListener('change', () => { this.setNewBoundsFromInputs() });
      this.west.addEventListener('change', () => { this.setNewBoundsFromInputs() });

      this.boundingBox.enable()
    }
  }

  setNewBoundsFromInputs() {
    this.boundingBox.setBounds(L.latLngBounds([this.south.value, this.west.value], [this.north.value, this.east.value]))
  }

  clampBounds(bounds) {
    try {
      let n = this.valBetween(bounds.getNorth(), -90, 90)
      let e = this.valBetween(bounds.getEast(), -180, 180)
      let s = this.valBetween(bounds.getSouth(), -90, 90)
      let w = this.valBetween(bounds.getWest(), -180, 180)
      return L.latLngBounds([s, w], [n, e])
    }
    catch (err) {
      return null;
    }
  }

  valBetween(val, min, max) {
    return (Math.min(max, Math.max(min, val)))
  }

  coverageToBounds(coverage) {
    try {
      let n = String(coverage).match(/northlimit=([\.\d\-]+)/m)
      let e = String(coverage).match(/eastlimit=([\.\d\-]+)/m)
      let s = String(coverage).match(/southlimit=([\.\d\-]+)/m)
      let w = String(coverage).match(/westlimit=([\.\d\-]+)/m)

      if (n && e && s && w) {
        return L.latLngBounds([s[1], w[1]], [n[1], e[1]])
      } else {
        return null
      }
    }
    catch (err) {
      return null
    }
  }

  boundsToCoverage(bounds) {
    try {
      let clamped_bounds = this.clampBounds(bounds);
      let n = clamped_bounds.getNorth().toFixed(4)
      let e = clamped_bounds.getEast().toFixed(4)
      let s = clamped_bounds.getSouth().toFixed(4)
      let w = clamped_bounds.getWest().toFixed(4)

      if (n && e && s && w) {
        return 'northlimit=' + n + '; ' +
                   'eastlimit=' + e + '; ' +
                   'southlimit=' + s + '; ' +
                   'westlimit=' + w + '; ' +
                   'units=degrees; ' +
                   'projection=EPSG:4326'
      } else {
        return ''
      }
    }
    catch (err) {
      return ''
    }
  }

  updateBboxInputs(bounds) {
    let clamped_bounds = this.clampBounds(bounds)
    this.north.value = clamped_bounds.getNorth().toFixed(4)
    this.east.value = clamped_bounds.getEast().toFixed(4)
    this.south.value = clamped_bounds.getSouth().toFixed(4)
    this.west.value = clamped_bounds.getWest().toFixed(4)
  }
}
