/* global UV, $, createUV */
import CDLTimer from 'viewer/cdl_timer'
import IIIFLogo from 'images/iiif-logo.svg'
import TakedownLogo from 'images/takedown.png'
import LeafletViewer from 'viewer/leaflet_viewer'
import TabManager from 'viewer/tab_manager'

export default class UVManager {
  async initialize () {
    this.bindLogin()
    this.bindResize()
    this.tabManager = new TabManager()
    this.tabManager.initialize()
    this.uvElement.hide()
    await this.loadUV()
    this.resize()
  }

  async loadUV () {
    return this.checkManifest()
      .then(this.createUV.bind(this))
      // If creating the UV fails, don't build leaflet.
      .then(() => { return this.buildLeafletViewer() })
      .catch(this.requestAuth.bind(this))
      .promise()
  }

  buildLeafletViewer () {
    this.leafletViewer = new LeafletViewer(this.figgyId, this.tabManager)
    return this.leafletViewer.loadLeaflet()
  }

  checkManifest () {
    return $.ajax(this.manifest, { type: 'HEAD' })
  }

  createUV (data, status, jqXHR) {
    this.tabManager.onTabSelect(() => setTimeout(() => this.resize(), 100))
    this.processTitle(jqXHR)
    this.uvElement.show()
    this.uv = createUV('#uv', {
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

  addViewerIcons () {
    const existingButton = document.querySelector('a.iiif-drag')
    const shareButton = document.querySelector('.footerPanel button.share')
    if (existingButton !== null || shareButton === null || shareButton.style.display === 'none') {
      return
    }
    const mobileShareButton = document.querySelector('.mobileFooterPanel button.share')
    // Pull link from the UV share popup.
    const policies = this.createPoliciesElement()

    shareButton.parentNode.insertBefore(policies.icon, shareButton.nextSibling)
    mobileShareButton.parentNode.insertBefore(policies.icon, mobileShareButton.nextSibling)

    shareButton.parentNode.insertBefore(this.createIIIFDragElement(), shareButton.nextSibling)
    mobileShareButton.parentNode.insertBefore(this.createIIIFDragElement(), mobileShareButton.nextSibling)

    const overlays = document.querySelector('.overlays')
    overlays.appendChild(policies.overlay)
    console.log(overlays)

    policies.icon.addEventListener('click', (e) => {
      e.preventDefault()

      if (window.getComputedStyle(policies.overlay).display === 'block') {
        console.log('change to display none')
        policies.overlay.style.display = 'none';
      } else {
        console.log('change to display block')
        policies.overlay.style.display = 'block';
      }
    })
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

  createTakedownElement () {
    const iconElement = document.createElement('a')
    iconElement.className = 'btn imageBtn takedown'
    iconElement.href = 'https://library.princeton.edu/takedown-request'
    iconElement.target = '_blank'
    iconElement.innerHTML = `<img src="${TakedownLogo}" style="width:30px; height=30px;"/> <span id="takedown-rights">Rights and Permissions</span>`
    return iconElement
  }

  createPoliciesElement () {
    const harmfulLanguageLink = document.createElement('a')
    harmfulLanguageLink.href = 'https://library.princeton.edu/statement-harmful-content'
    harmfulLanguageLink.target = '_blank'
    harmfulLanguageLink.innerHTML = 'Statement on Harmful Content'
    const harmfulLanguageListItem = document.createElement('li')
    harmfulLanguageListItem.appendChild(harmfulLanguageLink)

    const policiesMenu = document.createElement('ul')
    policiesMenu.style="top: -191.844px; left: 1px;"
    policiesMenu.appendChild(harmfulLanguageListItem)
    const policiesOverlayDiv = document.createElement('div')
    policiesOverlayDiv.className = 'overlay policies'
    policiesOverlayDiv.appendChild(policiesMenu)

    const iconElement = document.createElement('a')
    iconElement.className = 'btn imageBtn policies'

    iconElement.href = 'https://library.princeton.edu/statement-harmful-content'
    iconElement.target = '_blank'
    iconElement.innerHTML = `<img src="${TakedownLogo}" style="width:30px; height=30px;"/> <span id="takedown-rights">Policies</span>`

    return { icon: iconElement, overlay: policiesOverlayDiv }
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
    let tabHeight = 0
    if ($('#tab-container').is(':visible')) {
      tabHeight = $('#tab-container').outerHeight(true)
    }
    this.uvElement.width(windowWidth)
    this.uvElement.height(windowHeight - titleHeight - tabHeight)
    this.uvElement.children('div').height(windowHeight - titleHeight - tabHeight)
    if (this.uv) { this.uv.resize() }
    this.waitForElementToDisplay('button.share', 500, this.addViewerIcons.bind(this))
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
