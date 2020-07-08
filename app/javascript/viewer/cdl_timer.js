export default class CDLTimer {
  constructor (figgyId) {
    this.figgyId = figgyId
  }

  // Check time every second.
  async initializeTimer () {
    this.status = await this.fetchStatus()
    // If item isn't charged we're seeing it some other way - don't spin up a
    // timer.
    if (this.status.charged === false) { return }
    await this.checkTime()
    window.setInterval(() => { this.checkTime() }, 1000)
  }

  async checkTime () {
    const remainingTime = this.status.expires_at - this.currentTime
    if (remainingTime <= 0) {
      return this.exitViewer()
    } else {
      this.setTime(remainingTime)
    }
  }

  // Create an element inside the UV container with the time. It has to be
  // inside so that the remaining time still displays when full-screening the
  // UV.
  setTime (remainingTime) {
    const oldElement = document.getElementById('remaining-time')
    if (oldElement !== null) { oldElement.parentNode.removeChild(oldElement) }
    const timeElement = document.createElement('div')
    timeElement.setAttribute('id', 'remaining-time')
    timeElement.innerHTML = `Remaining Checkout Time: ${this.remainingTimeString(remainingTime)}`
    const uvPane = document.getElementById('uv').firstChild
    uvPane.insertBefore(timeElement, uvPane.firstChild)
  }

  remainingTimeString (seconds) {
    return new Date(seconds * 1000).toISOString().substr(11, 8)
  }

  exitViewer () {
    window.location.reload()
  }

  // Ruby's timestamp is in seconds, Javascript's is in milliseconds.
  get currentTime () {
    return Math.round(Date.now() / 1000)
  }

  async fetchStatus () {
    return fetch(`/cdl/${this.figgyId}/status`).then(response => response.json())
  }
}
