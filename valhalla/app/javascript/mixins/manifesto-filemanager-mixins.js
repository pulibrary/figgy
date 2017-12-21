import default_image from 'default.png'
import Pluralize from 'pluralize'

const ManifestoFilemanagerMixins = {

  mainSequence: function () {
    const s = this.getSequences()
    const main_sequence = s.filter((seq) => seq.id !== 'undefined')
    // the default Sequence is the first in the list
    return main_sequence[0]
  },

  getCanvasMainThumb: function (canvas) {
    const images = canvas.getImages()
    var thumb = default_image //'/packs/_/_/_/app/assets/images/default-1927ff44629d419a4bb2dfdc4317a78a.png'
    var services = images[0].getResource().getServices()
    if (services.length) {
      thumb = services[0].id + '/full/400,/0/default.jpg'
    }
    return thumb
  },

  getResourceId: function (canvas) {
    const images = canvas.getImages()
    const r = images[0].getResource()
    // the double id property is due to a bug in our manifests ...
    // see https://github.com/pulibrary/figgy/issues/598
    return r.id.id
  },

  getEnglishLabel: function (canvas) {
    const translations = canvas.getLabel()
    const english = translations.find(translation => translation.locale === "en-GB")
    return english.value
  },

  getThumbnailId: function () {
    const t = this.getThumbnail()
    var id = ''
    if (typeof t != 'undefined') {
      const parse = t.__jsonld.service["@id"].split('/')
      id = parse[parse.length-1]
    }
    return id
  },

  imageCollection: function (resource) {
    const s = this.mainSequence()
    const canvases = s.getCanvases()
    const viewDir = this.getViewingDirection()
    const viewHint = this.getViewingHint()
    var imageCollection = {}
    imageCollection.id = resource.id
    imageCollection.resourceClassName = Pluralize.singular(resource.class_name)
    imageCollection.startpage = ''
    if (typeof s.getStartCanvas() != 'undefined') {
      imageCollection.startpage = s.getStartCanvas()
    }
    imageCollection.thumbnail = this.getThumbnailId()
    imageCollection.viewingDirection = ''
    if (typeof viewDir != 'undefined') {
      imageCollection.viewingDirection = viewDir.value
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

}

export default ManifestoFilemanagerMixins
