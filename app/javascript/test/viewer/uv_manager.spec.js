import UVManager from 'viewer/uv_manager'
import jQ from 'jquery'
jest.mock('viewer/cdl_timer')
describe('UVManager', () => {
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
  function buildMocks (status) {
    // Mock jQuery
    const clickable = { click: () => clickable, on: () => clickable, is: () => clickable, outerHeight: () => clickable, width: () => clickable, height: () => clickable, hide: () => clickable, show: () => clickable }
    global.$ = jest.fn().mockImplementation(() => clickable)

    // Mock $.ajax
    const data = { status: status }
    const jqxhr = { getResponseHeader: () => null }
    global.$.ajax = jest.fn().mockImplementation(() => {
      if (status !== 200) { return jQ.Deferred().reject(data, status, jqxhr) } else { return jQ.Deferred().resolve(data, status, jqxhr) }
    })
    const getResult = jest.fn().mockImplementation(function (k) {
      if (k === 'manifest') { return 'https://localhost/12345/manifest' } else { return null }
    })
    // Mock UV Provider
    const provider = jest.fn().mockImplementation(() => {
      return { get: getResult }
    })
    global.UV = { URLDataProvider: provider }
    global.createUV = jest.fn()
    // Allow window location assign
    jest.spyOn(window.location, 'assign').mockImplementation(() => true)
  }

  describe('initialize', () => {
    it('redirects to viewer auth if the manifest 401s', async () => {
      buildMocks(401)

      // Initialize
      const uvManager = new UVManager()
      await uvManager.initialize()
      expect(window.location.assign).toHaveBeenCalledWith('/viewer/12345/auth')
    })
  })
})
