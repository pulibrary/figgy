import OpenSeadragon from 'openseadragon'
import navImages from './osd_nav_images'
export default class ModalViewer {
  constructor() {
    this.element = $(this.selector)
    $("a", this.element).unbind("click")
    $("body").on("click", this.selector, (event) => {
      event.stopPropagation()
      event.preventDefault()
      let manifest_url = $(event.currentTarget).attr("data-modal-manifest")
      let osd_viewer = $("picture[data-openseadragon]")
      let new_source = $("<source>", { class: "osd-image", src: manifest_url, media: "openseadragon" })
      $("#viewer-modal").modal()
      osd_viewer.height($(window).height()-100)
      if(this.osd !== undefined) {
        let viewer = this.osd.data("osdViewer")
        viewer.open(manifest_url)
      } else {
        osd_viewer.html("")
        new_source.appendTo(osd_viewer)
        let sources = osd_viewer.find('source[media="openseadragon"]');
        sources = $.map(sources, function(e) {
          return $(e).attr('src')
        })
        this.osd = OpenSeadragon({
          element: osd_viewer[0],
          prefixUrl: '',
          navImages: navImages,
          tileSources: sources
        })
      }
      return true
    })
  }

  get selector() {
    return "*[data-modal-manifest]"
  }
}
