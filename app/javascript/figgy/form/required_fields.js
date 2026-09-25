export class RequiredFields {
  // Monitors the form and runs the callback if any of the required fields change
  constructor(form, callback) {
    this.form = form
    this.callback = callback
    this.reload()
  }

  get areComplete() {
    return this.requiredFields.filter((n, elem) => { return this.isValuePresent(elem) } ).length === 0
  }

  isValuePresent(elem) {
    return ($(elem).val() === null) || ($(elem).val().length < 1)
  }

  // Reassign requiredFields because fields may have been added or removed.
  reload() {
    // ":input" matches all input, select or textarea fields.
    // Collections use trix as a wysiywg editor that has a required field in it,
    // ignore that one.
    this.requiredFields = this.form.find(':input[required]').not('trix-toolbar :input')
    this.requiredFields.change(this.callback)
  }
}
