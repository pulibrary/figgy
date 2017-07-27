export default class SelectTracker {
  constructor(element) {
    this.element = element
    this.element.data("original-value", this.element.val())
    this.element.on("change", this.check_changed)
    this.element.data("tracker", this)
  }

  reset() {
    console.log("Resetting")
    this.element.data("original-value", this.element.val())
  }

  get parent_persister() {
    return this.element.parents().filter(function() { return $(this).data("file_manager_member") }).first().data("file_manager_member")
  }

  get check_changed() {
    return () => {
      if(this.is_changed) {
        this.parent_persister.push_changed(this.element)
      } else {
        this.parent_persister.mark_unchanged(this.element)
      }
    }
  }

  get is_changed() {
    return String(this.element.val()) != String(this.original_value)
  }

  get original_value() {
    return this.element.data("original-value")
  }
}
