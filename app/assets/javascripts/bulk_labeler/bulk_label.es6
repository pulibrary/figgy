import Flash from "flash"
import LabelerActionsManager from "bulk_labeler/labeler_actions_manager"
import shift_enabled_selecting from "shift_selecting"
export default class BulkLabeler {
  constructor() {
    this.element = $("*[data-action=file-manager]")
    $("#foliate-settings").hide()
    $("#order-grid").selectable(
      {
        filter: ".panel",
        stop: this.stopped_label_select,
        selecting: shift_enabled_selecting(),
        cancel: "a,input,option,label,button,.ignore-select"
      }
    )
    this.actions_manager = new LabelerActionsManager($("#file-manager-tools .actions"))
    this.apply_button.disable()
    this.apply_button.click(this.apply_labels)
    this.initialize_radio_buttons()
    this.flash = new Flash
  }

  initialize_radio_buttons() {
    // Simple form doesn't add unique IDs to the form IDs, so need javascript to
    // fix them up.
    this.element.find("span.radio").each((index, element) => {
      element = $(element)
      let input = $("input[type=radio]", element)
      let label = $("label", element)
      let id = element.parents("li[data-reorder-id]").first().attr("data-reorder-id")
      let current_id = input.attr("id")
      input.attr("id", `${current_id}_${id}`)
      label.attr("for", input.attr("id"))
    })
    this.element.find("li input[type=radio]:checked").each(function(id, element) {
      element = $(element)
      let parent = element.parents("div").first()
      parent.attr("data-first-value", element.val())
    })
  }

  get apply_button() {
    return this.actions_manager.apply_button
  }
  get apply_labels() {
    return (event) => {
      event.preventDefault()
      let generator = this.generator
      let value = null
      let title_field = null
      for(let i of this.selected_elements.toArray()) {
        i = $(i)
        value = generator.next().value
        title_field = i.find("input.title")
        title_field.val(value)
        title_field.change()
      }
    }
  }

  get generator() {
    return this.actions_manager.generator
  }

  get selected_elements() {
    return this.element.find("li .panel.ui-selected")
  }

  get action_inputs() {
    return this.actions_manager.inputs
  }

  get stopped_label_select() {
    return () => {
      let selected_count = this.selected_elements.length
      if(selected_count > 0) {
        this.apply_button.enable()
        this.action_inputs.enable()
      } else {
        this.apply_button.disable()
        this.action_inputs.disable()
      }
    }
  }
}

