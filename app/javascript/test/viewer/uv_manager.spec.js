import UVManager from 'viewer/uv_manager'
describe('UVManager', () => {
  afterEach(() => {
    if (global.$ !== undefined) {
      global.$.mockClear()
      delete global.$
    }
    if (global.UV !== undefined) {
      delete global.UV
    }
  })
  function buildMocks (status) {
    // Mock jQuery
    const clickable = { click: () => clickable, on: () => clickable, is: () => clickable, outerHeight: () => clickable, width: () => clickable, height: () => clickable, hide: () => clickable }
    global.$ = jest.fn().mockImplementation(() => clickable)

    // Mock $.ajax
    const data = { status: status }
    const jqxhr = {}
    global.$.ajax = jest.fn().mockImplementation(() => {
      if (status !== 200) { return Promise.reject(data, status, jqxhr) } else { return Promise.resolve(data, status, jqxhr) }
    })
    const getResult = jest.fn().mockImplementation(function (k) {
      if (k === 'manifest') { return 'https://localhost/12345/manifest' } else { return null }
    })
    // Mock UV Provider
    const provider = jest.fn().mockImplementation(() => {
      return { get: getResult }
    })
    global.UV = { URLDataProvider: provider }
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
