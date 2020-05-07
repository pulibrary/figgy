export default class CollectionBagUploader {
  static closeModal () {
    $('#browse-everything-modal').modal('hide')
  }

  static appendElements (event) {
    const upload = event.detail
    const container = upload.containers.shift()

    $('#collection_bag_path').val(container.id)
    CollectionBagUploader.closeModal()
  }

  constructor () {
    window.addEventListener('browseEverything.upload', CollectionBagUploader.appendElements)

    // Special handling for Material UI in Bootstrap Modals
    $('#browse-everything-modal').on('show.bs.modal', e => {
      $(document).off('focusin.bs.modal', '**')
      const $modal = $('#browse-everything-modal')
      const modal = $modal.data('bs.modal')
      modal.enforceFocus = (e) => {}
    })
  }
}
