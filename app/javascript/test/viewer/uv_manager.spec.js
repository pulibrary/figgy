import UVManager from 'viewer/uv_manager'
import jQ from 'jquery'
import LeafletViewer from 'viewer/leaflet_viewer'
jest.mock('viewer/cdl_timer')
jest.mock('viewer/leaflet_viewer')
describe('UVManager', () => {
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
    if (global.UV !== undefined) {
      delete global.UV
    }
    if (global.createUV !== undefined) {
      delete global.createUV
    }
  })
  function mockJquery () {
    // Mock jQuery
    const clickable = { click: () => clickable, on: () => clickable, is: () => clickable, outerHeight: () => clickable, width: () => clickable, height: () => clickable, hide: () => clickable, show: () => clickable, children: () => clickable }
    global.$ = jest.fn().mockImplementation(() => clickable)
  }

  function mockManifests (status) {
    // Mock $.ajax
    const data = { status: status }
    const jqxhr = { getResponseHeader: () => null }
    global.$.ajax = jest.fn().mockImplementation(() => {
      if (status !== 200) { return jQ.Deferred().reject(data, status, jqxhr) } else { return jQ.Deferred().resolve(data, status, jqxhr) }
    })
  }

  function mockUvProvider (externalManifest = false) {
    const getResult = jest.fn().mockImplementation(function (k) {
      if (k === 'manifest') {
        if (externalManifest === true) {
          return 'https://example.org/other/iiif/manifest'
        } else {
          return 'https://localhost/concern/scanned_resources/12345/manifest'
        }
      } else if (k === 'config') {
        return 'https://figgy.princeton.edu/uv/uv_config.json'
      } else { return null }
    })

    const provider = jest.fn().mockImplementation(() => {
      return { get: getResult }
    })
    global.UV = { URLDataProvider: provider }
    global.createUV = jest.fn()
    // Allow window location assign
    jest.spyOn(window.location, 'assign').mockImplementation(() => true)
  }

  function stubQuery(embedHash) {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        status: 200,
        json: () => Promise.resolve(
          {
            "data": {
              "resourcesByFiggyIds": [
                {
                  "id": component_id,
                  "embed": embedHash
                }
              ]
            }
          }
        )
      })
    )
  }

  describe('initialize', () => {
    it('redirects to viewer auth if graph says unauthenticated', async () => {
      document.body.innerHTML = initialHTML
      mockJquery()
      mockUvProvider()
      stubQuery({
        "type": null,
        "content": null,
        "status": "unauthenticated"
      })

      // Initialize
      const uvManager = new UVManager()
      await uvManager.initialize()
      expect(window.location.assign).toHaveBeenCalledWith('/viewer/12345/auth')
      expect(LeafletViewer).not.toHaveBeenCalled()
    })

    it('redirects to viewer auth if the manifest 401s', async () => {
      document.body.innerHTML = initialHTML
      mockJquery()
      mockManifests(401)
      mockUvProvider()

      // Initialize
      const uvManager = new UVManager()
      await uvManager.initialize()
      expect(window.location.assign).toHaveBeenCalledWith('/viewer/12345/auth')
      expect(LeafletViewer).not.toHaveBeenCalled()
    })

    it('falls back to a default viewer URI if not using a figgy manifest', async () => {
      document.body.innerHTML = initialHTML
      mockJquery()
      mockManifests(401)
      mockUvProvider(true)

      // Initialize
      const uvManager = new UVManager()
      expect(uvManager.configURI).toEqual('https://figgy.princeton.edu/uv/uv_config.json')
    })
  })
})
