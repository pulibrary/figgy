import {StructureParser} from '@figgy/structure_parser'
import shift_enabled_selecting from '@figgy/shift_selecting'
export default class StructureManager {
  constructor() {
    this.initialize_sortable()
    this.initialize_selectable()
    this.bind_persist()
    this.add_section_button()
  }

  initialize_sortable() {
    $(".sortable").nestedSortable({
      handle: ".move",
      items: "li",
      toleranceElement: "> div",
      listType: "ul",
      placeholder: "placeholder",
      parentNodeFactory: this.new_node,
      preventExpansion: true,
      helper: function(e, item) {
        if ( ! item.hasClass("ui-selected") ) {
          item.parent().children(".ui-selected").removeClass("ui-selected")
          item.addClass("ui-selected")
        }

        var selected = item.parent().children(".ui-selected").clone()
        item.data("multidrag", selected).siblings(".ui-selected").remove()
        return $("<li/>").append(selected)
      },
      stop: function(e, ui) {
        var selected = ui.item.data("multidrag")
        ui.item.after(selected)
        ui.item.remove()
        $(".ui-selected").removeClass("ui-selected")
      },
      start: function(event, ui) {
        ui.placeholder.height(ui.item.height())
      },
      isTree: true,
      collapsedClass: "collapsed",
      expandedClass: "expanded"
    })
    $(".sortable").on("click", ".expand-collapse", function() {
      let parent = $(this).parents("li").first()
      parent.toggleClass("expanded")
      parent.toggleClass("collapsed")
    })
  }

  initialize_selectable() {
    $(".sortable").selectable({
      cancel: ".move,input,a,.expand-collapse,.ignore-select",
      filter: "li",
      selecting: shift_enabled_selecting()
    })
    $(".sortable").on("click", "*[data-action=remove-list]", function(event) {
      event.preventDefault()
      if(confirm("Delete this structure?")) {
        let parent_li = $(this).parents("li").first()
        let child_items = parent_li.children("ul").children()
        parent_li.before(child_items)
        parent_li.remove()
      }
    })
  }

  bind_persist() {
    $("*[data-action=submit-list]").click(function(event) {
      event.preventDefault()
      let element = $(".sortable")
      let serializer = new StructureParser(element)
      let klass = element.attr("data-class-name")
      let singular_klass = element.attr("data-singular-class-name")
      let id = element.attr("data-id")
      let url = `/concern/${klass}/${id}`
      let button = $(this)
      button.text("Saving..")
      button.addClass("disabled")
      $.ajax({
        type: "PUT",
        url: url,
        data: JSON.stringify({[singular_klass]: {'logical_structure': [serializer.serialize]}}),
        dataType: "json",
        contentType: "application/json"
      }).always(() => {
        button.text("Save")
        button.removeClass("disabled")
      })
    })
  }

  add_section_button() {
    let new_node = this.new_node
    $("*[data-action=add-to-list]").click(function(event) {
      event.preventDefault()
      let top_element = $(".sortable")
      let new_element = new_node()
      top_element.prepend(new_element)
    })
  }

  new_node() {
    return $("<li>", { class: "expanded" }).append(
      $("<div>").append(
        $("<div>", { class: "card" }).append(
          $("<div>", { class: "card-header" }).append(
            $("<div>", { class: "row" }).append(
              $("<div>", { class: "title" }).append(
                $("<span>", { class: "move glyphicon glyphicon-move" })).append(
                $("<span>", { class: "glyphicon expand-collapse" })).append(
                $("<input>", { type: "text", name: "label", id: "label" }))).append(
              $("<div>", { class: "toolbar" }).append(
                $("<a>", { href: "", "data-action": "remove-list", title: "Remove "}).append(
                  $("<span>", { class: "glyphicon glyphicon-remove" })
                )
              )
            )
          )
        )
      )
    )
  }
}
