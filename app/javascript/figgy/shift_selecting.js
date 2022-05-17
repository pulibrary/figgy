export default function shift_enabled_selecting() {
  let prev = -1
  return function(e, ui) { // on select
    let curr = $(ui.selecting.tagName, e.target).index(ui.selecting) // get selecting item index
    if(e.shiftKey && prev > -1) { // if shift key was pressed and there is previous - select them all
      $(ui.selecting.tagName, e.target).slice(Math.min(prev, curr), 1 + Math.max(prev, curr)).addClass("ui-selected")
    } else {
      prev = curr // othervise just save prev
    }
  }
}
