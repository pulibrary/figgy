import CDLTimer from 'viewer/cdl_timer'
describe('CDLTimer', () => {
  const initialHTML =
    '<meta name="csrf-token" content="YxKJmi/UUkd9MN+10GTo9/xKPqAvVdUIWtKxXzH9VpjVVwFLbT1swegQ6rcTZ517G5Y88pr/ndxzoyulCVZeQA==">' +
    '<form id="return-early-form" action="/viewer" method="post">' +
    '  <input type="hidden" name="authenticity_token" value="y+lCzpQ4pMHgLI+re6Gzm5y9XBo04YAvcpVS6DMP1h7RmQw1Zuq6QsVorC0UUvdpB5xXuNqUK/EbbSAv4ngFpw==" autocomplete="off">' +
    '  <input type="hidden" name="id" id="id">' +
    '</form>' +
  '<div id="uv"><div></div></div>'

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
        json: () => json,
        ok: true
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)
      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()
      expect(timer.status.charged).toBe(false)
    })

    it('displays a timer if <= 5 minutes left', async () => {
      document.body.innerHTML = initialHTML

      const json = {
        'charged': true,
        'available': false,
        'expires_at': Math.round(Date.now() / 1000) + 300
      }
      const mockFetchPromise = Promise.resolve({ // 3
        json: () => json,
        ok: true
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)
      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()
      expect(document.getElementById('remaining-time').innerHTML).toMatch(/Remaining Checkout Time: \d\d:\d\d:\d\d/)
    })

    it("doesn't add a return button on error", async () => {
      document.body.innerHTML = initialHTML

      const json = {
        'status': 500,
        'error': 'Internal Server Error'
      }

      const mockFetchPromise = Promise.resolve({
        json: () => json,
        ok: false
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)

      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()

      let buttonElement = document.getElementById('return-early-button')
      expect(buttonElement).toBe(null)
    })

    it('displays an expiration time if > 5 minutes left', async () => {
      document.body.innerHTML = initialHTML

      const expireTime = Math.round(Date.now() / 1000) + 600
      const json = {
        'charged': true,
        'available': false,
        'expires_at': expireTime
      }
      const mockFetchPromise = Promise.resolve({ // 3
        json: () => json,
        ok: true
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)
      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()

      const time = new Date(expireTime * 1000).toLocaleTimeString()

      expect(document.getElementById('remaining-time').innerHTML).toMatch(`Expires At: ${time}`)
    })

    it('places the return button before the timer', async () => {
      document.body.innerHTML = initialHTML

      const expireTime = Math.round(Date.now() / 1000) + 600
      const json = {
        'charged': true,
        'available': false,
        'expires_at': expireTime
      }
      const mockFetchPromise = Promise.resolve({
        json: () => json,
        ok: true
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)

      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()

      let buttonElement = document.getElementById('return-early-button')
      expect(buttonElement.nextSibling.id).toBe('remaining-time')
    })

    it('updates the return form and links the button to the form', async () => {
      document.body.innerHTML = initialHTML

      const expireTime = Math.round(Date.now() / 1000) + 600
      const json = {
        'charged': true,
        'available': false,
        'expires_at': expireTime
      }
      const mockFetchPromise = Promise.resolve({
        json: () => json,
        ok: true
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)
      const id = 'b627a6ce-6717-4dd0-a16a-7a0c0b8a5788'
      const timer = new CDLTimer(id)
      await timer.initializeTimer()

      const formElement = document.getElementById('return-early-form')
      console.log(formElement.firstChild)
      expect(document.querySelector("input[name='authenticity_token']").getAttribute('value')).toBe('YxKJmi/UUkd9MN+10GTo9/xKPqAvVdUIWtKxXzH9VpjVVwFLbT1swegQ6rcTZ517G5Y88pr/ndxzoyulCVZeQA==')
      expect(formElement.getAttribute('action')).toBe(`/cdl/${id}/return`)
      expect(formElement.lastChild.getAttribute('value')).toBe(id)
      const buttonElement = document.getElementById('return-early-button')
      expect(buttonElement.firstChild.getAttribute('form')).toBe('return-early-form')
    })

    it('reloads the page when the hold expires', async () => {
      const json = {
        'charged': true,
        'available': false,
        'expires_at': Math.round(Date.now() / 1000) - 1
      }
      const mockFetchPromise = Promise.resolve({ // 3
        json: () => json,
        ok: true
      })
      global.fetch = jest.fn().mockImplementation(() => mockFetchPromise)

      jest.spyOn(window.location, 'reload').mockImplementation(() => true)

      const timer = new CDLTimer('b627a6ce-6717-4dd0-a16a-7a0c0b8a5788')
      await timer.initializeTimer()
      expect(window.location.reload).toHaveBeenCalled()
    })
  })
})
