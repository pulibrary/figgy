import Vue from 'vue/dist/vue.common.js'
import AjaxSelect from '../components/ajax-select.vue'

function appendAjaxSelect (ajaxInput) {
  const inputId = ajaxInput.id
  const inputType = ajaxInput.getAttribute('ajax_select_type')
  const newHTML = `<ajax-select target-id='${inputId}' type-name='${inputType}'></ajax-select>`
  ajaxInput.insertAdjacentHTML('beforebegin', newHTML)
}

function mountVueComponents (rootElement) {
  const $elements = $(rootElement).prev('.nested-fields').find('input[ajax_select_type]')
  $elements.each((i,e) => {
    appendAjaxSelect(e)
    const $ajaxSelect = $(e).prev('ajax-select')

    new Vue({
      el: $ajaxSelect[0],
      components: {
        'ajax-select': AjaxSelect
      },
      data: {
        options: []
      }
    })
  })
}

function handleCocoonAfterInsert (event, elements) {
  elements.each(() => {
    mountVueComponents(this)
  })
}

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
