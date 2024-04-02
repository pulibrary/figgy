import DownloadNotifier from '@figgy/download_notifier.js'
import consumer from '@channels/consumer'

describe('DownloadNotifier', () => {
  // Stub window.location with a spy.
  const realLocation = window.location

  beforeAll(() => {
    delete window.location
    window.location = { ...realLocation, assign: vi.fn() }
  })

  afterAll(() => {
    window.location = realLocation
  })

  it('subscribes to a consumer and responds to pctComplete', () => {
    document.body.innerHTML = '<div class="progress-bar" role="progressbar" aria-valuenow="25" aria-valuemin="0" aria-valuemax="100" data-track-id="744a6023-a3ae-4e89-96e3-77cfde75748b">0%</div>'

    const notifier = new DownloadNotifier()
    const subscription = consumer.subscriptions.subscriptions[0]

    // Ensure it's attached to the GenerateFileNotificationChannel with the ID
    // of the resource we're tracking
    expect(subscription.identifier).toEqual(JSON.stringify({ channel: 'GenerateFileNotificationChannel', id: '744a6023-a3ae-4e89-96e3-77cfde75748b' }))
    expect(subscription.received).toEqual(expect.any(Function))

    // Ensure it resizes the progress bar when sent a pctComplete message
    subscription.received({ pctComplete: 50 })
    expect(window.getComputedStyle(notifier.element, null).getPropertyValue('width')).toEqual('50%')
    expect(notifier.element.textContent).toEqual('50%')

    // Ensure it redirects when it hits 100%
    subscription.received({ pctComplete: 100, redirectUrl: '/downloads/resource-id/file/file-id' })
    expect(window.location.assign).toBeCalledWith('/downloads/resource-id/file/file-id')
  })
})
