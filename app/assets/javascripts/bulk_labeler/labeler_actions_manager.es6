import lg from "bulk_labeler/label_generator"
export default class LabelerActionsManager {
  constructor(element) {
    this.element = element
    this.apply_button.disable()
    this.inputs.disable()
    this.element.find("input[name=method]").change(function() {
      var element = $(this)
      if(element.val() == "foliate") {
        $("#foliate-settings").show()
      } else {
        $("#foliate-settings").hide()
      }
    })
  }

  on_apply(func) {
    return this.apply_button.click(func)
  }

  get generator() {
    return lg.pageLabelGenerator(this.first,
                                        this.method,
                                        this.frontLabel,
                                        this.backLabel,
                                        this.startWith,
                                        this.unitLabel,
                                        this.bracket)
  }

  get first() {
    let val = this.element.find("input[name=start_with]").val()
    if(isNaN(val) || isNaN(parseInt(val))) {
      return val
    } else {
      return parseInt(val)
    }
  }

  get method() {
    return this.element.find("input[name=method]:checked").val()
  }

  get frontLabel() {
    let front_label_element = this.element.find("input[name=front_label]")
    if(front_label_element.is(":visible")) {
      return front_label_element.val()
    } else {
      return ""
    }
  }

  get backLabel() {
    let back_label_element = this.element.find("input[name=back_label]")
    if(back_label_element.is(":visible")) {
      return back_label_element.val()
    } else {
      return ""
    }
  }

  get startWith() {
    return this.element.find("input[name=foliate_start_with]:checked").val()
  }

  get unitLabel() {
    return this.element.find("input[name=unit_label]").val()
  }

  get bracket() {
    return this.element.find("input[name=bracket]").prop("checked")
  }

  get apply_button() {
    return new ActionsButton(this.element.find("*[data-action=apply-labels]"))
  }

  get inputs() {
    return new ActionsButton(this.element.find("input"))
  }
}

class ActionsButton {
  constructor(element) {
    this.element = element
  }

  disable() {
    this.element.prop("disabled", true)
  }

  enable() {
    this.element.prop("disabled", false)
  }

  click(func) {
    return this.element.click(func)
  }

  prop(property, value) {
    return this.element.prop(property, value)
  }
}
