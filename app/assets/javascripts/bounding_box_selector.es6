export default class BoundingBoxSelector {
  constructor($element) {
    this.$inputId = $($element).data().inputId
    this.$coverage = $($element).data().coverage
    this.$readOnly = $($element).data().readOnly
    this.initialize_map()
  }

  initialize_map() {
    let initialBounds;
    let that = this;
    if (!this.$coverage && this.$inputId ) {
      this.$coverage = $(this.$inputId).val()
    }

    if ((this.$coverage) && (this.$coverage.length !== 0)) {
      initialBounds = this.coverageToBounds(this.$coverage)
      this.updateBboxInputs(initialBounds)
    } else {
      initialBounds = L.latLngBounds([[-50, -100], [72, 100]])
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

    if (this.$readOnly) {
      new L.Rectangle(initialBounds, { color: 'blue', weight: 2, opacity: 0.9 }).addTo(map)
    } else {
      let boundingBox = new L.BoundingBox({ bounds: initialBounds,
                                     buttonPosition: 'topright', }).addTo(map)

      boundingBox.on('change', function() {
        $("#" + that.$inputId).val(that.boundsToCoverage(this.getBounds()))
        that.updateBboxInputs(this.getBounds())
      })

      boundingBox.enable()
    }
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
      let n = clamped_bounds.getNorth().toFixed(6)
      let e = clamped_bounds.getEast().toFixed(6)
      let s = clamped_bounds.getSouth().toFixed(6)
      let w = clamped_bounds.getWest().toFixed(6)

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
    $('#bbox-north').val(clamped_bounds.getNorth().toFixed(6))
    $('#bbox-east').val(clamped_bounds.getEast().toFixed(6))
    $('#bbox-south').val(clamped_bounds.getSouth().toFixed(6))
    $('#bbox-west').val(clamped_bounds.getWest().toFixed(6))
  }
}
