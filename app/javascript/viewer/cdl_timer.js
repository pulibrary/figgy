export default class CDLTimer {
  constructor (figgyId) {
    this.figgyId = figgyId
  }

  // Check time every second.
  async initializeTimer () {
    try {
      this.status = await this.fetchStatus()
      // If item isn't charged we're seeing it some other way - don't spin up a
      // timer.
      // if (this.status.charged === false) { return }
      this.setupReturnForm()
      const uvPane = document.getElementById('uv').firstChild
      uvPane.insertBefore(this.returnButton(), uvPane.firstChild)
      await this.checkTime()
      window.setInterval(() => { this.checkTime() }, 1000)
    } catch (e) {
    }
  }

  // We don't know the id when this form is set up in rails
  //   so we adjust it a bit here
  setupReturnForm () {
    // Set form submission target (we don't know the id in the view)
    const formAction = `/cdl/${this.figgyId}/return`
    const form = document.getElementById('return-early-form')
    form.setAttribute('action', formAction)
    form.lastElementChild.setAttribute('value', this.figgyId)
  }

  // button to return early
  returnButton () {
    const buttonElement = document.createElement('div')
    buttonElement.setAttribute('id', 'cdl-viewer')
    const html = `<div id="return-early-button"><input type="submit" value="Return this item" class="btn btn-primary" form="return-early-form"></div>`
    buttonElement.innerHTML = html
    return buttonElement
  }

  async checkTime () {
    // const remainingTime = this.status.expires_at - this.currentTime
    const remainingTime = 100
    if (remainingTime <= 0) {
      // return this.exitViewer()
      this.setTime(remainingTime)
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
    timeElement.innerHTML = this.timeString(remainingTime)
    // place it after the return button
    const buttonElement = document.getElementById('return-early-button')
    buttonElement.parentNode.insertBefore(timeElement, buttonElement.nextSibling)
  }

  timeString (remainingSeconds) {
    if (remainingSeconds > 300) {
      return `Expires At: ${this.localExpireTime}`
    } else {
      return `Remaining Checkout Time: ${this.remainingTimeString(remainingSeconds)}`
    }
  }

  get localExpireTime () {
    const expiresDate = new Date(this.status.expires_at * 1000)
    return expiresDate.toLocaleTimeString()
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

  okCheck (response) {
    if (response.ok === true) { return response }
    return Promise.reject(response)
  }

  async fetchStatus () {
    return fetch(`/cdl/${this.figgyId}/status`).then(this.okCheck).then(response => response.json())
  }
}
