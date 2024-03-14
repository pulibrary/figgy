import consumer from '@channels/consumer'
export default class DownloadNotifier {
  constructor () {
    if (!this.element) {
      return
    }
    this.writeStatus(0)
    consumer.subscriptions.create(
      { channel: 'DownloadNotificationChannel', id: this.trackId },
      {
        received: this.received.bind(this)
      }
    )
  }

  get element () {
    return document.getElementById('progress-notifier')
  }

  get trackId () {
    return this.element.getAttribute('data-track-id')
  }

  received (data) {
    this.writeStatus(data.pct_complete)
    if (data.pct_complete === 100) {
      window.location = `/downloads/${data.resource_id}/file/${data.file_id}`
    }
  }

  writeStatus (pct) {
    this.element.textContent = `${pct}%`
  }
}
