export default class DerivativeForm {
  constructor() {
    this.element = $(".rederive")
    var that = this
    this.element.click(function(event) {
      event.preventDefault()
      that.onclick(event)
    })
  }

  onclick(event) {
    $.ajax({
      type: "PUT",
      url: event.currentTarget.attributes.href.value,
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
