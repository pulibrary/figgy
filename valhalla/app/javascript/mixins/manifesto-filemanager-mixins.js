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
    var imageCollection = {}
    imageCollection.id = resource.id
    imageCollection.startpage = null
    if (this.startCanvas != 'undefined') {
      imageCollection.startpage = this.startCanvas
    }
    imageCollection.thumbnail = null
    if (this.thumbnail != 'undefined') {
      imageCollection.thumbnail = this.thumbnail
    }
    imageCollection.images = canvases.map(canvas => ({
      label: this.getEnglishLabel(canvas),
      id: this.getResourceId(canvas),
      page_type: "single",
      url: this.getCanvasMainThumb(canvas)
    }))
    return imageCollection
  },

}

export default ManifestoFilemanagerMixins
