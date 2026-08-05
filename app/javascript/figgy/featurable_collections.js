/**
 * Renders the "Feature in Digital Collections" checkboxes on a resource edit
 * form.
 *
 * A resource can be highlighted in any collection it belongs to, as well as in
 * an ancestor ephemera project. Collection membership is edited on the same
 * page, so the checkbox list is rebuilt every time the collections select
 * changes rather than being rendered once server side.
 *
 * Checked ids are remembered across re-renders, so removing a collection and
 * adding it back doesn't silently drop the highlight.
 */
export default class FeaturableCollections {
  /**
   * @param {HTMLElement} element container rendered by the featurable edit field partial
   */
  constructor (element) {
    this.element = element
    this.optionList = element.querySelector('.featurable-collections-options')
    this.inputName = element.dataset.featurableInputName
    this.emptyMessage = element.dataset.featurableEmptyMessage
    this.fixedOptions = parseOptions(element.dataset.featurableFixedOptions)
    this.selectedIds = new Set(parseJSON(element.dataset.featurableSelected, []).map(String))
    this.collectionSelect = element.dataset.featurableCollectionSelect
      ? document.querySelector(element.dataset.featurableCollectionSelect)
      : null

    this.render = this.render.bind(this)
    this.bindEvents()
    this.render()
  }

  bindEvents () {
    if (!this.collectionSelect) return

    this.collectionSelect.addEventListener('change', this.render)
    // bootstrap-select replaces the select with its own widget and announces
    // changes through a jQuery-only event, which native listeners don't see.
    if (window.jQuery) {
      window.jQuery(this.collectionSelect).on('changed.bs.select', this.render)
    }
  }

  /**
   * Everything the resource could currently be highlighted in.
   * @returns {Array<{id: string, label: string}>}
   */
  featurableOptions () {
    const options = this.fixedOptions.concat(this.selectedCollections())
    const seen = new Set()
    return options.filter((option) => {
      if (seen.has(option.id)) return false
      seen.add(option.id)
      return true
    })
  }

  /**
   * @returns {Array<{id: string, label: string}>} collections chosen in the select
   */
  selectedCollections () {
    if (!this.collectionSelect) return []

    return Array.from(this.collectionSelect.selectedOptions)
      .filter((option) => option.value)
      .map((option) => ({ id: option.value, label: option.text.trim() }))
  }

  render () {
    if (!this.optionList) return

    this.optionList.innerHTML = ''
    const options = this.featurableOptions()

    if (options.length === 0) {
      this.optionList.appendChild(this.buildEmptyMessage())
      return
    }

    options.forEach((option) => this.optionList.appendChild(this.buildCheckbox(option)))
  }

  buildEmptyMessage () {
    const message = document.createElement('p')
    message.className = 'form-text text-muted featurable-collections-empty'
    message.textContent = this.emptyMessage || ''
    return message
  }

  /**
   * @param {{id: string, label: string}} option
   * @returns {HTMLElement} a bootstrap form-check for one featuring target
   */
  buildCheckbox (option) {
    const wrapper = document.createElement('div')
    wrapper.className = 'form-check'

    const checkbox = document.createElement('input')
    checkbox.type = 'checkbox'
    checkbox.className = 'form-check-input'
    checkbox.name = this.inputName
    checkbox.value = option.id
    checkbox.id = `featurable_${option.id}`
    checkbox.checked = this.selectedIds.has(option.id)
    checkbox.addEventListener('change', () => {
      if (checkbox.checked) {
        this.selectedIds.add(option.id)
      } else {
        this.selectedIds.delete(option.id)
      }
    })

    const label = document.createElement('label')
    label.className = 'form-check-label'
    label.htmlFor = checkbox.id
    label.textContent = option.label

    wrapper.appendChild(checkbox)
    wrapper.appendChild(label)
    return wrapper
  }
}

/**
 * @param {string} value JSON serialized array of {id, label} objects
 * @returns {Array<{id: string, label: string}>}
 */
function parseOptions (value) {
  return parseJSON(value, [])
    .filter((option) => option && option.id)
    .map((option) => ({ id: String(option.id), label: String(option.label || '') }))
}

function parseJSON (value, fallback) {
  if (!value) return fallback

  try {
    const parsed = JSON.parse(value)
    return Array.isArray(parsed) ? parsed : fallback
  } catch {
    return fallback
  }
}
