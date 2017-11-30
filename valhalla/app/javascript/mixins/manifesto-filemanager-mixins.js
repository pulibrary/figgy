const ManifestoFilemanagerMixins = {

  mainSequence: function () {
    // mainSequence is the one without an id (not ideal since it could have an id)
    const s = this.getSequences()
    const main_sequence = s.filter((seq) => seq.id !== 'undefined')
    return main_sequence[0]
  },

  getCanvasMainThumb: function (canvas) {
    const images = canvas.getImages()
    var thumb = "http://via.placeholder.com/300x400"
    var services = images[0].getResource().getServices()
    if (services.length) {
      thumb = services[0].id + '/full/400,/0/default.jpg'
    }
    return thumb
  },

  getResourceId: function (canvas) {
    const images = canvas.getImages()
    const r = images[0].getResource()
    // this seems to be a bug in manifesto ...
    // getResource() returns an object instead of a string
    return r.id.id
  },

  getEnglishLabel: function (canvas) {
    const translations = canvas.getLabel()
    const english = translations.find(translation => translation.locale === "en-GB")
    return english.value
  },

  imageCollection: function (resource) {
    const s = this.mainSequence()
    const canvases = s.getCanvases()
    const viewDir = this.getViewingDirection()
    const viewHint = this.getViewingHint()
    var imageCollection = {}
    imageCollection.id = resource.id
    imageCollection.startpage = ''
    if (typeof this.startCanvas != 'undefined') {
      imageCollection.startpage = this.startCanvas
    }
    imageCollection.thumbnail = ''
    if (typeof this.thumbnail != 'undefined') {
      imageCollection.thumbnail = this.thumbnail
    }
    imageCollection.viewingDirection = ''
    if (typeof viewDir != 'undefined') {
      imageCollection.viewingDirection = this.mapViewDir(viewDir.value)
    }
    imageCollection.viewingHint = ''
    if (typeof viewHint != 'undefined') {
      imageCollection.viewingHint = viewHint.value
    }
    imageCollection.images = canvases.map(canvas => ({
      label: this.getEnglishLabel(canvas),
      id: this.getResourceId(canvas),
      page_type: "single",
      url: this.getCanvasMainThumb(canvas)
    }))
    return imageCollection
  },

  mapViewDir: function (value) {
    // we need this because vue binding does not like values with hyphens
    // because they cannot be used as js properties
    const map = [ {short: "ltr", long: "left-to-right"},
                  {short: "rtl", long: "right-to-left"},
                  {short: "ttb", long: "top-to-bottom"},
                  {short: "btt", long: "bottom-to-top"},
                ]
    const viewDir = map.find(val => val.long === value)
    return viewDir.short
  },

}

export default ManifestoFilemanagerMixins
