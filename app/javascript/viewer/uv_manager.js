/* global UV, $, createUV */
import CDLTimer from '@viewer/cdl_timer'
import IIIFLogo from '@images/iiif-logo.svg'
import StatementOnHarmfulContentIcon from '@images/statement.png'
import TakedownLogo from '@images/copyright.svg'
import LeafletViewer from '@viewer/leaflet_viewer'
import TabManager from '@viewer/tab_manager'

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
    if (this.isFiggyManifest) {
      const result = await this.checkFiggyStatus()
      if (result.embed.status === 'unauthenticated') {
        return window.location.assign('/viewer/' + this.figgyId + '/auth')
      } else if (result.embed.status === 'authorized') {
        this.displayNotice(result)
        this.createUV(null, null, result)
        await this.buildLeafletViewer()
      }
    } else {
      return this.createUV()
    }
  }

  async checkFiggyStatus() {
    let url = "/graphql";
    if (this.authToken) {
      url = `${url}?auth_token=${this.authToken}`
    }
    var data = JSON.stringify({ query:`{
        resource(id: "` + this.figgyId + `"){
          id,
          __typename,
          label,
          embed {
            type,
            content,
            status
          },
          notice {
            heading,
            acceptLabel,
            textHtml
          }
        }
       }`
    })
    return fetch(url,
      {
        method: "POST",
        credentials: 'include',
        body: data,
        headers: {
          'Content-Type': 'application/json',
        }
      }
    )
      .then((response) => response.json())
      .then((response) => response.data.resource)
  }

  displayNotice (graphqlData) {
    if (graphqlData.notice === null) { return }
    document.getElementById('notice-modal').classList.remove('d-none')
    const headingElement = document.getElementById('notice-heading')
    headingElement.innerHTML = graphqlData.notice.heading
    const textElement = document.getElementById('notice-text')
    textElement.innerHTML = graphqlData.notice.textHtml
    const acceptButton = document.getElementById('notice-accept')
    acceptButton.value = graphqlData.notice.acceptLabel
    acceptButton.addEventListener('click', (e) => {
      e.preventDefault()
      document.getElementById('notice-modal').classList.add('d-none')
    })
  }

  // Adds a tabbed viewer for Leaflet to show rasters, especially for mosaics.
  async buildLeafletViewer () {
    this.leafletViewer = new LeafletViewer(this.figgyId, this.tabManager)
    return this.leafletViewer.loadLeaflet()
  }

  createUV (data, status, graphqlData) {
    this.tabManager.onTabSelect(() => setTimeout(() => this.resize(), 100))
    this.processTitle(graphqlData)
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

    shareButton.parentNode.insertBefore(this.createTakedownElement(), shareButton.nextSibling)
    mobileShareButton.parentNode.insertBefore(this.createTakedownElement(), mobileShareButton.nextSibling)

    shareButton.parentNode.insertBefore(this.createStatementElement(), shareButton.nextSibling)
    mobileShareButton.parentNode.insertBefore(this.createStatementElement(), mobileShareButton.nextSibling)

    shareButton.parentNode.insertBefore(this.createIIIFDragElement(), shareButton.nextSibling)
    mobileShareButton.parentNode.insertBefore(this.createIIIFDragElement(), mobileShareButton.nextSibling)
    this.resize()
  }

  createIIIFDragElement () {
    const link = document.querySelector('a.imageBtn.iiif').href
    const iconElement = document.createElement('a')
    iconElement.className = 'btn imageBtn iiif-drag'
    iconElement.href = link
    iconElement.target = '_blank'
    iconElement.innerHTML = `<img src="${IIIFLogo}" style="width:25px; height=25px;"/>`
    return iconElement
  }

  createTakedownElement () {
    const iconElement = document.createElement('a')
    iconElement.className = 'btn imageBtn takedown'
    iconElement.href = 'https://library.princeton.edu/takedown-request'
    iconElement.target = '_blank'
    iconElement.innerHTML = `<img src="${TakedownLogo}" style="width:25px; height=25px;"/> <span id="takedown-rights">Rights and Permissions</span>`
    return iconElement
  }

  createStatementElement () {
    const iconElement = document.createElement('a')
    iconElement.className = 'btn imageBtn statement'
    iconElement.href = 'https://library.princeton.edu/statement-harmful-content'
    iconElement.target = '_blank'
    iconElement.innerHTML = `<img src="${StatementOnHarmfulContentIcon}" style="width:25px; height=25px;"/> <span id="statement-on-harmful-content">Statement on Harmful Content</span>`
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

  get figgyId () {
    return this.manifest.replace('/manifest', '').replace(/.*\//, '').replace(/\?.*/, '')
  }

  get authToken () {
    const url = new URL(this.manifest)
    const authToken = url.searchParams.get('auth_token')
    return authToken
  }

  get isFiggyManifest () {
    return this.manifest.includes('concern') && this.manifest.includes('/manifest')
  }

  get configURI () {
    if (this.isFiggyManifest) {
      return '/viewer/config/' + this.manifest.replace('/manifest', '').replace(/.*\//, '') + '.json'
    } else {
      return this.urlDataProvider.get('config')
    }
  }

  processTitle (graphqlData) {
    if (graphqlData === undefined || graphqlData.__typename !== 'Playlist') {
      return
    }
    var title = graphqlData.label
    var titleElement = document.getElementById('title')
    titleElement.textContent = title
    titleElement.style.display = 'block'
    this.resize()
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
    this.waitForElementToDisplay('button.share', 1000, this.addViewerIcons.bind(this))
    if (this.uv) { this.uv.resize() }
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
