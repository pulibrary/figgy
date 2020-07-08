import CDLTimer from 'viewer/cdl_timer'
describe('CDLTimer', () => {
  afterEach(() => {
    if (global.fetch !== undefined) {
      global.fetch.mockClear()
      delete global.fetch
    }
  })

  describe('initialization', () => {
    it('sets a figgyId', () => {
      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      expect(timer.figgyId).toBe('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
    })
  })

  describe('initializeTimer', () => {
    it('sets a status', async () => {
      const json = {
        'charged': false,
        'available': false
      }
      const mockFetchPromise = Promise.resolve({ // 3
        json: () => json
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)
      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()
      expect(timer.status.charged).toBe(false)
    })

    it('updates the expire time', async () => {
       document.body.innerHTML =
        '<div id="uv">' +
        '  <div>' +
        '  </div>'
        '</div>';

      const json = {
        'charged': true,
        'available': false,
        'expires_at': Math.round(Date.now() / 1000) + 600
      }
      const mockFetchPromise = Promise.resolve({ // 3
        json: () => json
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)
      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()
      expect(document.getElementById('remaining-time').innerHTML).toMatch(/Remaining Checkout Time: \d\d:\d\d:\d\d/)
    })

    it('reloads the page when the hold expires', async () => {
      const json = {
        'charged': true,
        'available': false,
        'expires_at': Math.round(Date.now() / 1000) - 1
      }
      const mockFetchPromise = Promise.resolve({ // 3
        json: () => json
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)

      jest.spyOn(window.location, 'reload').mockImplementation( () => true)

      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()
      expect(window.location.reload).toHaveBeenCalled
    })
  })
})
