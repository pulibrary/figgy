import _ from 'lodash'
// import system from 'lux-design-system'

vi.unmock('lodash')
_.debounce = vi.fn((fn) => fn);

// jsdom doesn't let you mock window.location anymore, so replace that
// implementation for all tests so we can mock it. Solution found here:
// https://www.benmvp.com/blog/mocking-window-location-methods-jest-jsdom/
const oldWindowLocation = window.location

beforeAll(() => {
  delete window.location

  window.location = Object.defineProperties(
    {},
    {
      ...Object.getOwnPropertyDescriptors(oldWindowLocation),
      assign: {
        configurable: true,
        value: vi.fn()
      },
      reload: {
        configurable: true,
        value: vi.fn()
      }
    }
  )
})
afterAll(() => {
  // restore `window.location` to the original `jsdom`
  // `Location` object
  window.location = oldWindowLocation
})
