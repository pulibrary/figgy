import consumer from '@channels/consumer'
export default class DownloadNotifier {
  constructor () {
    ActionCable.logger.enabled = true
    if (!this.element) {
      return
    }
    consumer.subscriptions.create(
      { channel: 'GenerateFileNotificationChannel', id: this.trackId },
      { received: this.received.bind(this) }
    )
  }

  get element () {
    return document.querySelector('.progress-bar[data-track-id]')
  }

  get trackId () {
    return this.element.getAttribute('data-track-id')
  }

  received (data) {
    this.element.style.width = `${data.pctComplete}%`
    this.element.textContent = `${data.pctComplete}%`
    if (data.pctComplete === 100) {
      window.location.assign(data.redirectUrl)
    }
  }
}
