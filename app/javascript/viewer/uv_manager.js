/* global UV, $, createUV */
export default class UVManager {
  initialize () {
    this.bindLogin()
    this.bindResize()
    this.uvElement.hide()
    this.loadUV()
  }

  loadUV () {
    this.checkManifest().done(this.createUV.bind(this)).fail(this.requestAuth.bind(this))
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
  }

  requestAuth (data, status) {
    if (data.status === 401) {
      if (this.manifest.includes(window.location.host)) {
        const figgyId = this.manifest.replace('/manifest', '').replace(/.*\//, '')
        window.location.href = '/viewer/' + figgyId + '/auth'
      }
    }
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
