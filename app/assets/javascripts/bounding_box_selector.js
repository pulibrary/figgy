function boundingBoxSelector(options) {
  var inputId = options.inputId;
  var initialBounds;
  var coverage = options.coverage;
  if (!coverage && inputId ) {
    var coverage = $(inputId).val();
  }

  if (coverage) {
    initialBounds = coverageToBounds(coverage);
    updateBboxInputs(initialBounds);
  } else {
    initialBounds = L.latLngBounds([[-50, -100], [72, 100]]);
  };

  var map = L.map('bbox', {
    maxBounds: [[-100, -180], [100, 180]],
    touchZoom: false,
    scrollWheelZoom: false
  }).fitBounds(initialBounds);

  L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
    maxZoom: 18
  }).addTo(map);
  L.Control.geocoder({ position: 'topleft' }).addTo(map);

  if (options.readonly) {
    new L.Rectangle(initialBounds, { color: 'white', weight: 2, opacity: 0.9 }).addTo(map);
  } else {
    boundingBox = new L.BoundingBox({ bounds: initialBounds,
                                   buttonPosition: 'topright', }).addTo(map);

    boundingBox.on('change', function() {
      $(inputId).val(boundsToCoverage(this.getBounds()));
      updateBboxInputs(this.getBounds())
    });

    boundingBox.enable();
  }
};

function clampBounds(bounds) {
  try {
    n = valBetween(bounds.getNorth(), -90, 90);
    e = valBetween(bounds.getEast(), -180, 180);
    s = valBetween(bounds.getSouth(), -90, 90);
    w = valBetween(bounds.getWest(), -180, 180);
    return L.latLngBounds([s, w], [n, e]);
  }
  catch (err) {
    return null;
  }
};

function valBetween(val, min, max) {
  return (Math.min(max, Math.max(min, val)));
};

function coverageToBounds(coverage) {
  try {
    n = String(coverage).match(/northlimit=([\.\d\-]+)/m);
    e = String(coverage).match(/eastlimit=([\.\d\-]+)/m);
    s = String(coverage).match(/southlimit=([\.\d\-]+)/m);
    w = String(coverage).match(/westlimit=([\.\d\-]+)/m);

    if (n && e && s && w) {
      return L.latLngBounds([s[1], w[1]], [n[1], e[1]]);
    } else {
      return null;
    }
  }
  catch (err) {
    return null;
  }
};

function boundsToCoverage(bounds) {
  try {
    bounds = clampBounds(bounds);
    n = bounds.getNorth().toFixed(6);
    e = bounds.getEast().toFixed(6);
    s = bounds.getSouth().toFixed(6);
    w = bounds.getWest().toFixed(6);

    if (n && e && s && w) {
      return 'northlimit=' + n + '; ' +
                 'eastlimit=' + e + '; ' +
                 'southlimit=' + s + '; ' +
                 'westlimit=' + w + '; ' +
                 'units=degrees; ' +
                 'projection=EPSG:4326';
    } else {
      return '';
    }
  }
  catch (err) {
    return '';
  }
};

function updateBboxInputs(bounds) {
  bounds = clampBounds(bounds);
  $('#bbox-north').val(bounds.getNorth().toFixed(6));
  $('#bbox-east').val(bounds.getEast().toFixed(6));
  $('#bbox-south').val(bounds.getSouth().toFixed(6));
  $('#bbox-west').val(bounds.getWest().toFixed(6));
};
