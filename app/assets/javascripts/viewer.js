function loadUV () {
  let urlDataProvider = new UV.URLDataProvider(false)
  var manifest = urlDataProvider.get('manifest')
  $('#loginContainer').hide()
  $('#uv').hide()
  $('#login').click(function (e) {
    e.preventDefault()
    var child = window.open('/users/auth/cas?login_popup=true')
    var timer = setInterval(checkChild, 200)

    function checkChild () {
      if (child.closed) {
        loadUV()
        clearInterval(timer)
      }
    }
  })
  $.ajax(manifest, { type: 'HEAD' }).done(function (data, status, jqXHR) {
    var linkHeader = jqXHR.getResponseHeader('Link')
    if (linkHeader) {
      var segments = linkHeader.split(';')
      var titleMatch = /title="(.+?)"/.exec(linkHeader)
      if (titleMatch[1]) {
        var title = titleMatch[1]
        var titleElement = document.getElementById('title')
        titleElement.textContent = title
        titleElement.style.display = 'block'
        resize()
      }
    }
    $('#uv').show()
    manifestUri = urlDataProvider.get('manifest')
    configUri = '/viewer/config/' + manifestUri.replace('/manifest', '').replace(/.*\//, '') + '.json'
    uv = createUV('#uv', {
      root: 'uv',
      iiifResourceUri: manifestUri,
      configUri: configUri,
      collectionIndex: Number(urlDataProvider.get('c', 0)),
      manifestIndex: Number(urlDataProvider.get('m', 0)),
      sequenceIndex: Number(urlDataProvider.get('s', 0)),
      canvasIndex: Number(urlDataProvider.get('cv', 0)),
      rangeId: urlDataProvider.get('rid', 0),
      rotation: Number(urlDataProvider.get('r', 0)),
      xywh: urlDataProvider.get('xywh', ''),
      embedded: true
    }, urlDataProvider)
  }).fail(function (data, status) {
    if (data.status == 401) {
      $('#loginContainer').show()
    }
  })
}
window.addEventListener('uvLoaded', loadUV, false)

var $UV = $('#uv')
function resize () {
  var windowWidth = window.innerWidth
  var windowHeight = window.innerHeight
  var titleHeight = $('#title').outerHeight($('#title').is(':visible'))
  $UV.width(windowWidth)
  $UV.height(windowHeight - titleHeight)
}
$(function () {
  $(window).on('resize', function () {
    resize()
  })
  resize()
})
