/* global UV, $, createUV */
import CDLTimer from 'viewer/cdl_timer'
import IIIFLogo from 'images/iiif-logo.svg'
export default class UVManager {
  async initialize () {
    this.bindLogin()
    this.bindResize()
    this.uvElement.hide()
    await this.loadUV()
  }

  async loadUV () {
    return this.checkManifest().then(this.createUV.bind(this)).catch(this.requestAuth.bind(this)).promise()
  }

  checkManifest () {
    return $.ajax(this.manifest, { type: 'HEAD' })
  }

  createUV (data, status, jqXHR) {
    this.processTitle(jqXHR)
    this.uvElement.show()
    createUV('#uv', {
      root: 'uv',
      iiifResourceUri: this.manifest,
      configUri: this.configURI,
      collectionIndex: Number(this.urlDataProvider.get('c', 0)),
      manifestIndex: Number(this.urlDataProvider.get('m', 0)),
      sequenceIndex: Number(this.urlDataProvider.get('s', 0)),
      canvasIndex: Number(this.urlDataProvider.get('cv', 0)),
      rangeId: this.urlDataProvider.get('rid', 0),
      rotation: Number(this.urlDataProvider.get('r', 0)),
      xywh: this.urlDataProvider.get('xywh', ''),
      embedded: true
    }, this.urlDataProvider)
    this.cdlTimer = new CDLTimer(this.figgyId)
    this.cdlTimer.initializeTimer()
  }

  addIIIFIcon () {
    const existingButton = document.querySelector('a.iiif-drag')
    const shareButton = document.querySelector('.footerPanel button.share')
    if (existingButton !== null || shareButton === null || shareButton.style.display === "none") {
      return
    }
    const mobileShareButton = document.querySelector('.mobileFooterPanel button.share')
    // Pull link from the UV share popup.
    shareButton.parentNode.insertBefore(this.createIIIFDragElement(), shareButton.nextSibling)
    mobileShareButton.parentNode.insertBefore(this.createIIIFDragElement(), mobileShareButton.nextSibling)
  }

  createIIIFDragElement () {
    const link = document.querySelector('a.imageBtn.iiif').href
    const iconElement = document.createElement('a')
    iconElement.className = 'btn imageBtn iiif-drag'
    iconElement.href = link
    iconElement.target = '_blank'
    iconElement.innerHTML = `<img src="${IIIFLogo}" style="width:30px; height=30px;"/>`
    return iconElement
  }

  waitForElementToDisplay (selector, time, callback) {
    if (document.querySelector(selector) != null) {
      callback()
    } else {
      setTimeout(function () {
        this.waitForElementToDisplay(selector, time, callback)
      }.bind(this), time)
    }
  }

  requestAuth (data, status) {
    if (data.status === 401) {
      if (this.manifest.includes(window.location.host)) {
        window.location.assign('/viewer/' + this.figgyId + '/auth')
      }
    }
  }

  get figgyId () {
    return this.manifest.replace('/manifest', '').replace(/.*\//, '')
  }

  get configURI () {
    return '/viewer/config/' + this.manifest.replace('/manifest', '').replace(/.*\//, '') + '.json'
  }

  processTitle (jqXHR) {
    var linkHeader = jqXHR.getResponseHeader('Link')
    if (linkHeader) {
      var titleMatch = /title="(.+?)"/.exec(linkHeader)
      if (titleMatch[1]) {
        var title = titleMatch[1]
        var titleElement = document.getElementById('title')
        titleElement.textContent = title
        titleElement.style.display = 'block'
        this.resize()
      }
    }
  }

  resize () {
    const windowWidth = window.innerWidth
    const windowHeight = window.innerHeight
    const titleHeight = $('#title').outerHeight($('#title').is(':visible'))
    this.uvElement.width(windowWidth)
    this.uvElement.height(windowHeight - titleHeight)
    this.waitForElementToDisplay('button.share', 500, this.addIIIFIcon.bind(this))
  }

  bindResize () {
    $(window).on('resize', () => this.resize())
    this.resize()
  }

  bindLogin () {
    $('#login').click(function (e) {
      e.preventDefault()
      var child = window.open('/users/auth/cas?login_popup=true')
      var timer = setInterval(checkChild, 200)

      function checkChild () {
        if (child.closed) {
          clearInterval(timer)
          window.location.reload()
        }
      }
    })
  }

  get urlDataProvider () {
    return new UV.URLDataProvider(false)
  }

  get manifest () {
    return this.urlDataProvider.get('manifest')
  }

  get uvElement () {
    return $('#uv')
  }
}
