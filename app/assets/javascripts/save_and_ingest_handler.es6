export default class SaveAndIngestHandler {
  constructor() {
    this.button_element = $(this.button_selector)
    this.field_element = $(this.field_element_selector)
    this.info_element = $(this.info_element_selector)
    this.reset_button()
    this.field_element.change((e) => {
      this.reset_button()
      this.button_element.val('Searching...')
<<<<<<< HEAD
      $.getJSON(`/concern/scanned_resources/save_and_ingest/${this.field_element.val()}`)
=======
      $.getJSON(`/concern/scanned_resources/save_and_ingest/${this.encode_periods(this.field_element.val())}.json`)
>>>>>>> d8616123... adds lux order manager to figgy
        .done((data) => {
          if(data.exists == true) {
            this.reset_button()
            this.button_element.prop('disabled', false)
            if(data.file_count != 0)
              this.info_element.text(`Ingest ${data.file_count} files from ${data.location}`)
            else
              this.info_element.text(`Ingest ${data.volume_count} volumes from ${data.location}`)
          } else {
            this.reset_button()
          }
        })
    })
  }

  reset_button() {
    this.button_element.attr('disabled', true)
    this.button_element.val('Save and Ingest')
    this.info_element.text('')
  }

<<<<<<< HEAD
=======
  encode_periods(id) {
    return id.replace(/\./g, '%2E')
  }

>>>>>>> d8616123... adds lux order manager to figgy
  get button_selector() {
    return "*[data-save-and-ingest]"
  }

  get field_element_selector() {
    return "*[data-field='source_metadata_identifier_ssim']"
  }

  get info_element_selector() {
    return "#save-and-ingest-info"
  }
}
