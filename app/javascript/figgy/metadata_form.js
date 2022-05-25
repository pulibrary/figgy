export default class MetadataForm {
  constructor() {
    this.form = $(".extract_metadata")
    this.element = this.form.find('button')
    this.element.click(this.onclick)
  }

  onclick(event) {
    $.ajax({
      type: "PUT",
      url: $(this).parents('.extract_metadata').attr('action'),
      data: $(this).parents('.extract_metadata').serializeArray(),
      dataType: 'json'
    }).done(function(data, textStatus, response) {
      $('.flash-message span.text')
        .text("Metadata is being extracted")
        .parent()
        .removeAttr('hidden')
    }).fail(function(response, textStatus, errorThrown) {
      $('.flash-message span.text')
        .text("Metadata cannot be extracted")
        .parent()
        .removeClass('alert-success')
        .addClass('alert-danger')
        .removeAttr('hidden')
    })
  }
}
