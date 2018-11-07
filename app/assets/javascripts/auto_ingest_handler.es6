export default class AutoIngestHandler {
  constructor() {
    this.button_element = $('#auto-ingest-button')
    this.info_element = $('#auto-ingest-info')
    $.getJSON(`/concern/coins/${this.button_element.attr("data-id")}/discover_files`)
      .done((data) => {
        if(data.exists == true) {
          this.button_element.prop('disabled', false)
          this.button_element.attr('value', 'Auto Ingest')
          if(data.file_count != 0)
            this.info_element.text(`Ingest ${data.file_count} files from numismatics/${data.location}`)
        }
      })
  }
}
