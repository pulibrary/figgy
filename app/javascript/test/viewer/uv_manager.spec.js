import UVManager from 'viewer/uv_manager'
import jQ from 'jquery'
import LeafletViewer from 'viewer/leaflet_viewer'
jest.mock('viewer/cdl_timer')
jest.mock('viewer/leaflet_viewer')
describe('UVManager', () => {
  const initialHTML =
    '<h1 id="title" class="lux-heading h1" style="display: none;"></h1>' +
    '<div id="notice-modal" class="d-none"><h2 id="notice-heading"></h2><div id="notice-text"></div><input id="notice-accept" value="View Content" type="submit"></input></div>' +
    '<div class="container--tabs">' +
        '<section class="row">' +
        '<ul class="nav nav-tabs" id="tab-container">' +
        '<li class="active"><a href="#tab-1">Sheets</a></li>' +
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

  function mockUvProvider (externalManifest = false, authToken = null) {
    const getResult = jest.fn().mockImplementation(function (k) {
      if (k === 'manifest') {
        if (externalManifest === true) {
          return 'https://example.org/other/iiif/manifest'
        } else {
          if (authToken === null) {
            return 'https://localhost/concern/scanned_resources/12345/manifest'
          } else {
            return `https://localhost/concern/scanned_resources/12345/manifest?auth_token=${authToken}`
          }
        }
      } else if (k === 'config') {
        return 'https://figgy.princeton.edu/uv/uv_config.json'
      } else { return null }
    })

    // This makes it so global.UV.URLDataProvider.get returns our mock data
    const provider = jest.fn().mockImplementation(() => {
      return { get: getResult }
    })
    global.UV = { URLDataProvider: provider }
    global.createUV = jest.fn()
    // Allow window location assign
    jest.spyOn(window.location, 'assign').mockImplementation(() => true)
  }

  let figgy_id = "12345"
  function stubQuery(embedHash, noticeHash=null,label='Test', type='ScannedResource') {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        status: 200,
        json: () => Promise.resolve(
          {
            "data": {
              "resource":
                {
                  "id": figgy_id,
                  "__typename": type,
                  "embed": embedHash,
                  "label": label,
                  "notice": noticeHash
                }
            }
          }
        )
      })
    )
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('initialize', () => {
    it('loads a viewer and title for a playlist', async () => {
      document.body.innerHTML = initialHTML
      mockJquery()
      mockUvProvider()
      stubQuery({
        "type": "html",
        "content": "<iframe src='https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/78e15d09-3a79-4057-b358-4fde3d884bbb/manifest'></iframe>",
        "status": "authorized"
      },
        null,
        "Test Playlist",
        "Playlist"
      )

      // Initialize
      const uvManager = new UVManager()
      await uvManager.initialize()
      expect(document.getElementById('title').innerHTML).toBe('Test Playlist')
    })

    it('passes on an auth token to graphql', async () => {
      document.body.innerHTML = initialHTML
      mockJquery()
      mockUvProvider(false, '12')
      stubQuery({
        'type': 'html',
        'content': '<iframe src="https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/78e15d09-3a79-4057-b358-4fde3d884bbb/manifest"></iframe>',
        'status': 'authorized'
      },
        null,
        'Test Playlist',
        'Playlist'
      )

      // Initialize
      const uvManager = new UVManager()
      await uvManager.initialize()
      expect(document.getElementById('title').innerHTML).toBe('Test Playlist')
      expect(global.fetch.mock.calls[0][0]).toBe('/graphql?auth_token=12')
      expect(JSON.parse(global.fetch.mock.calls[0][1].body).query).toMatch('resource(id: "12345")')
    })

    it('presents a click through for a senior thesis', async () => {
      document.body.innerHTML = initialHTML
      mockJquery()
      mockUvProvider()
      stubQuery({
        "type": "html",
        "content": "<iframe src='https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/78e15d09-3a79-4057-b358-4fde3d884bbb/manifest'></iframe>",
        "status": "authorized",
      },
        { "heading": "Terms and Conditions for Using Princeton University Senior Theses", "acceptLabel": "Accept", "textHtml": "<p>The Princeton University Senior Theses" }
      )

      // Initialize
      const uvManager = new UVManager()
      await uvManager.initialize()
      expect(document.getElementById('notice-heading').innerHTML).toBe('Terms and Conditions for Using Princeton University Senior Theses')
      expect(document.getElementById('notice-text').innerHTML).toMatch('<p>The Princeton University Senior Theses')
      expect(document.getElementById('notice-modal').classList.contains('d-none')).toBe(false)
      expect(document.getElementById('notice-accept').value).toBe("Accept")
      document.getElementById('notice-accept').click()
      expect(document.getElementById('notice-modal').classList.contains('d-none')).toBe(true)
    })

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

    it('falls back to a default viewer URI if not using a figgy manifest', async () => {
      document.body.innerHTML = initialHTML
      mockJquery()
      mockUvProvider(true)

      // Initialize
      const uvManager = new UVManager()
      expect(uvManager.configURI).toEqual('https://figgy.princeton.edu/uv/uv_config.json')
    })
  })
})
