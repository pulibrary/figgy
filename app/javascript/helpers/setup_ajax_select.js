// Inserts an ajax-select component before every input with a ajax_select_type
// attribute. Example:  `<input ajax_select_type="Place"/>`
export default function setupAjaxSelect () {
  const ajaxInputs = document.querySelectorAll('input[ajax_select_type]')
  for (var i = 0; i < ajaxInputs.length; i++) {
    const ajaxInput = ajaxInputs[i]
    const inputId = ajaxInput.id
    const inputType = ajaxInput.getAttribute('ajax_select_type')
    const newHTML = `<ajax-select target-id='${inputId}' type-name='${inputType}'></ajax-select>`
    ajaxInput.insertAdjacentHTML('beforebegin', newHTML)
  }
}
