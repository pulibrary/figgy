export default class FileSetForm {
  constructor($element) {
    this.$formElement = $element
    this.$fileInputElements = $element.find('input[type="file"]')
    this.$submitElement = $element.find('input[type="submit"]')

    this.$fileInputElements.data('_object', this)
    this.$fileInputElements.change(this.onchange)
    // Update the DOM upon instantiation
    this.update()
  }

  update() {
    let fileInputValues = this.$fileInputElements.map((_i, element) => element.value).toArray()
    if(fileInputValues.reduce((u, v) => u || v))
      this.$submitElement.prop('disabled', false)
    else
      this.$submitElement.prop('disabled', true)
  }

  onchange(event) {
    let that = $(this).data('_object')
    that.update()
  }
}
