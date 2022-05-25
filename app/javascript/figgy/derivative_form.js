export default class DerivativeForm {
  constructor() {
    this.form = $(".rederive")
    this.element = this.form.find('button')
    this.element.click(this.onclick)
  }

  onclick(event) {
    $.ajax({
      type: "PUT",
      url: $(this).parents('.rederive').attr('action'),
      data: $(this).parents('.rederive').serializeArray(),
      dataType: 'json'
    }).done(function(data, textStatus, response) {
      $('.flash-message span.text')
        .text("Derivatives are being regenerated")
        .parent()
        .removeAttr('hidden')
    }).fail(function(response, textStatus, errorThrown) {
      $('.flash-message span.text')
        .text("Derivatives cannot be regenerated")
        .parent()
        .removeClass('alert-success')
        .addClass('alert-danger')
        .removeAttr('hidden')
    })
  }
}
