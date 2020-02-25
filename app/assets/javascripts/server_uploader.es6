export default class ServerUploader {
  constructor () {
    window.addEventListener('browseEverything.upload', ServerUploader.appendElements)

    // Special handling for Material UI in Bootstrap Modals
    $('#browse-everything-modal').on('show.bs.modal', e => {
      $(document).off('focusin.bs.modal', '**')
      const $modal = $('#browse-everything-modal')
      const modal = $modal.data('bs.modal')
      modal.enforceFocus = (e) => {}
    })
  }

  static submitFiles () {
    $('#browse-everything-modal').modal('hide')
    $('#browse-everything-form').submit()
  }

  static appendElements (event) {
    const upload = event.detail
    const $input = $(`<input type="hidden" name="browse_everything[uploads][]" value="${upload.id}" />`)
    $('#browse-everything-form').append($input)
    ServerUploader.submitFiles()
  }
}
