import { createApp } from 'vue'
import AjaxSelect from '../components/ajax-select.vue'

// Inserts an ajax-select component before every input with a ajax_select_type
// attribute. Example:  `<input ajax_select_type="Place"/>`
export function setupAjaxSelect () {
  const ajaxInputs = document.querySelectorAll('input[ajax_select_type]')
  for (var i = 0; i < ajaxInputs.length; i++) {
    const ajaxInput = ajaxInputs[i]
    appendAjaxSelect(ajaxInput)
  }
}

export function setupCocoonLinks () {
  const cocoonLinks = document.querySelectorAll('.links')
  cocoonLinks.forEach(element => {
    // This needs to trigger the Vue components
    // jQuery needs to be used here, otherwise I could not find a solution with addEventListener
    const $element = $(element)
    $element.on('cocoon:after-insert', handleCocoonAfterInsert)
  })
}

function appendAjaxSelect (ajaxInput) {
  const inputId = ajaxInput.id
  const inputType = ajaxInput.getAttribute('ajax_select_type')
  const newHTML = `<ajax-select target-id='${inputId}' type-name='${inputType}'></ajax-select>`
  ajaxInput.insertAdjacentHTML('beforebegin', newHTML)
}

function mountNestedVueComponent (element) {
  const app = {
      data () {
        return { options: [] }
      }
  }
  const createMyApp = () => createApp(app)
  appendAjaxSelect(element)
  const ajaxSelect = $(element).prev('ajax-select')
  const parent = $(ajaxSelect[0]).parent()[0]
  createMyApp()
    .component('ajax-select', AjaxSelect)
    .mount(parent)
}

function handleCocoonAfterInsert (event, elements) {
  elements.each(() => {
    const nestedElement = $(this).prev('.nested-fields').find('input[ajax_select_type]')[0]
    mountNestedVueComponent(nestedElement)
  })
}
