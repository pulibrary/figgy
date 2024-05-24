import LeafletViewer from '../../viewer/leaflet_viewer'
import jQ from 'jquery'
import L from 'leaflet'
import TabManager from '../../viewer/tab_manager'
vi.mock('leaflet')
describe('LeafletViewer', () => {
  const initialHTML =
    '<h1 id="title" class="lux-heading h1" style="display: none;"></h1>' +
    '<div class="container--tabs">' +
        '<section class="row">' +
        '<ul class="nav nav-tabs" id="tab-container">' +
        '<li class="active"><a href="#tab-1">Default</a></li>' +
        '<li id="map-tab" class=""><a href="#map-tab-content">Map</a></li>' +
        '</ul>' +
        '<div class="tab-content">' +
        '<div id="tab-1" class="tab-pane active">' +
        '<div id="view" class="document-viewers widget-list">' +
        '<div class="intrinsic-container intrinsic-container-16x9" id="viewer-container">' +
        '<div id="uv" class="uv"></div>' +
        '</div>' +
        '</div>' +
        '</div> ' +
        '<div id="map-tab-content" class="tab-pane" data-tilemetadata="https://localhost:3000/tilemetadata">' +
        '<div class="document-viewers widget-list">' +
        '<div class="intrinsic-container intrinsic-container-16x9" id="viewer-container">' +
        '<div id="leaflet" class="leaflet"></div>' +
        '</div>' +
        '</div>' +
        '</div>' +
        '</div>' +
        '</section>' +
    '</div>'
  afterEach(() => {
    if (global.$ !== undefined) {
      global.$.mockClear()
      delete global.$
    }
  })
  function buildMocks (status) {
    // Mock jQuery
    global.$ = vi.fn().mockImplementation(() => null)

    // Mock $.ajax
    const data = {
      'tilejson': '2.2.0',
      'version': '1.0.0',
      'scheme': 'xyz',
      'tiles': [
        'https://map-tiles-staging.princeton.edu/mosaicjson/tiles/WebMercatorQuad/{z}/{x}/{y}@1x?url=s3%3A%2F%2Ffiggy-geo-staging%2Fd0%2Ff6%2F71%2Fd0f6711c6647425aa21271a8aa5239b8%2Fmosaic-3ecb0a4058255b66cb52557af05f49ac.json&rescale=0%2C255'
      ],
      'minzoom': 8,
      'maxzoom': 13,
      'bounds': [
        75,
        8.999950016607578,
        76.49996228779234,
        9.999999999949978
      ],
      'center': [
        75.74998114389618,
        9.499975008278778,
        8
      ]
    }
    const jqxhr = { getResponseHeader: () => null }
    global.$.ajax = vi.fn().mockImplementation(() => {
      if (status !== 200) { return jQ.Deferred().reject(data, status, jqxhr) } else { return jQ.Deferred().resolve(data, status, jqxhr) }
    })

    // Mock Leaflet
    const mapMock = { addTo: () => {} }
    L.tileLayer.mockImplementation(() => mapMock)
  }

  describe('initialize', () => {
    it('does nothing if tile result is 404', async () => {
      document.body.innerHTML = initialHTML
      buildMocks(404)

      // Spy on TabManager event binding.
      const bindMock = vi.spyOn(TabManager.prototype, 'onTabSelect')
      const tabManager = new TabManager()
      // Initialize
      const leafletViewer = new LeafletViewer('1', tabManager)
      await leafletViewer.loadLeaflet()
      expect(bindMock).not.toHaveBeenCalled()
      // Hidden tabs
      expect(document.getElementById('tab-container').style.display).toBe('')
      expect(document.getElementById('map-tab').style.display).toBe('')
    })
    it('binds tabs on a 200', async () => {
      document.body.innerHTML = initialHTML
      buildMocks(200)

      // Spy on TabManager event binding.
      const bindMock = vi.spyOn(TabManager.prototype, 'onTabSelect')
      const tabManager = new TabManager()
      // Initialize
      const leafletViewer = new LeafletViewer('1', tabManager)
      await leafletViewer.loadLeaflet()
      // Make sure tabs are bound
      expect(bindMock).toHaveBeenCalled()
      // Make sure tabs are visible
      expect(document.getElementById('tab-container').style.display).toBe('block')
      expect(document.getElementById('map-tab').style.display).toBe('block')
    })
  })
})
