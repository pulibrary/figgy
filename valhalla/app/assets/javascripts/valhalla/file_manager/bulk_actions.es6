export default class BulkActionManager {
  constructor(element) {
    this.sortable_element.on("selectablestop", this.stopped_selecting)
    this.element = element
  }
  get stopped_selecting() {
    return () => {
      let selected_count = this.selected_elements.length
      if(selected_count > 0) {
        this.initialize_bulk()
      } else {
        this.element.hide()
        this.element.find("input[name=bulk_hint]").off("change")
        this.element.find("input[name=bulk_hint]").prop('checked', false)
      }
    }
  }

  initialize_bulk() {
    let master = this
    if(this.all_values_the_same(this.selected_viewing_hint_values)) {
      let selected_val = this.selected_viewing_hint_values[0]
      this.element.find(`input[name=bulk_hint][value="${selected_val}"]`).prop('checked', true)
    }
    this.element.find("input[name=bulk_hint]").on("change", function(event) {
      let val = $(this).val()
      master.selected_viewing_hints.prop("checked", false)
      master.selected_viewing_hints.filter(`*[value="${val}"]`).prop("checked", true).change()
    })
    this.element.show()
  }

  get selected_elements() {
    return this.sortable_element.find("li .panel.ui-selected")
  }

  get selected_viewing_hints() {
    return this.selected_elements.find('input[name="book[viewing_hint]"]')
  }

  get selected_viewing_hint_values() {
    return this.selected_viewing_hints.filter(":checked").map(function() {return $(this).val()}).toArray()
  }

  get sortable_element() {
    return $("#order-grid")
  }

  all_values_the_same(array) {
    for(var i = 1; i < array.length; i++)
    {
        if(array[i] !== array[0])
            return false
    }
    return true
  }
}
