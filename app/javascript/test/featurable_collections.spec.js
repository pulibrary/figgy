import FeaturableCollections from '../figgy/featurable_collections.js'

const COLLECTION_ONE = '11111111-1111-1111-1111-111111111111'
const COLLECTION_TWO = '22222222-2222-2222-2222-222222222222'
const PROJECT = '33333333-3333-3333-3333-333333333333'

// Renders the markup produced by records/edit_fields/_featurable.html.erb
// alongside the collections select it reads from.
const buildForm = ({ selected = [], options = [], selectedCollections = [] } = {}) => {
  document.body.innerHTML = `
    <form>
      <select class="member-of-collection-ids" multiple>
        <option value="${COLLECTION_ONE}">Collection One</option>
        <option value="${COLLECTION_TWO}">Collection Two</option>
      </select>
      <div class="form-group featurable-collections"
           data-featurable-input-name="scanned_resource[featurable][]"
           data-featurable-selected='${JSON.stringify(selected)}'
           data-featurable-options='${JSON.stringify(options)}'
           data-featurable-collection-select=".member-of-collection-ids"
           data-featurable-empty-message="Add this resource to a collection.">
        <input type="hidden" name="scanned_resource[featurable][]" value="">
        <div class="featurable-collections-options"></div>
      </div>
    </form>
  `

  const select = document.querySelector('.member-of-collection-ids')
  selectedCollections.forEach((id) => {
    select.querySelector(`option[value="${id}"]`).selected = true
  })

  return {
    select,
    element: document.querySelector('.featurable-collections')
  }
}

const renderedCheckboxes = () =>
  Array.from(document.querySelectorAll('.featurable-collections-options input[type="checkbox"]'))

const labelTexts = () =>
  Array.from(document.querySelectorAll('.featurable-collections-options label')).map((l) => l.textContent)

describe('FeaturableCollections', () => {
  it('renders a checkbox for each collection the resource belongs to', () => {
    const { element } = buildForm({
      options: [
        { id: COLLECTION_ONE, label: 'Collection One' },
        { id: COLLECTION_TWO, label: 'Collection Two' }
      ],
      selectedCollections: [COLLECTION_ONE, COLLECTION_TWO]
    })

    new FeaturableCollections(element)

    expect(renderedCheckboxes().map((input) => input.value)).toEqual([COLLECTION_ONE, COLLECTION_TWO])
    expect(labelTexts()).toEqual(['Collection One', 'Collection Two'])
    expect(renderedCheckboxes().map((input) => input.name)).toEqual([
      'scanned_resource[featurable][]',
      'scanned_resource[featurable][]'
    ])
  })

  it('checks the boxes the resource is already featured in', () => {
    const { element } = buildForm({
      selected: [COLLECTION_TWO],
      options: [
        { id: COLLECTION_ONE, label: 'Collection One' },
        { id: COLLECTION_TWO, label: 'Collection Two' }
      ],
      selectedCollections: [COLLECTION_ONE, COLLECTION_TWO]
    })

    new FeaturableCollections(element)

    expect(renderedCheckboxes().map((input) => input.checked)).toEqual([false, true])
  })

  it('includes an ancestor ephemera project alongside the collections', () => {
    const { element } = buildForm({
      options: [
        { id: COLLECTION_ONE, label: 'Collection One' },
        { id: PROJECT, label: 'Test Project' }
      ],
      selected: [PROJECT],
      selectedCollections: [COLLECTION_ONE]
    })

    new FeaturableCollections(element)

    expect(renderedCheckboxes().map((input) => input.value)).toEqual([COLLECTION_ONE, PROJECT])
    expect(labelTexts()).toEqual(['Collection One', 'Test Project'])
    expect(renderedCheckboxes()[1].checked).toBe(true)
  })

  it('keeps the ephemera project when the collections are edited', () => {
    const { element, select } = buildForm({
      options: [
        { id: COLLECTION_ONE, label: 'Collection One' },
        { id: PROJECT, label: 'Test Project' }
      ],
      selectedCollections: [COLLECTION_ONE]
    })

    new FeaturableCollections(element)

    select.querySelector(`option[value="${COLLECTION_ONE}"]`).selected = false
    select.dispatchEvent(new Event('change'))

    expect(labelTexts()).toEqual(['Test Project'])
  })

  it('updates the list when a collection is added or removed', () => {
    const { element, select } = buildForm({
      options: [{ id: COLLECTION_ONE, label: 'Collection One' }],
      selectedCollections: [COLLECTION_ONE]
    })

    new FeaturableCollections(element)
    expect(labelTexts()).toEqual(['Collection One'])

    select.querySelector(`option[value="${COLLECTION_TWO}"]`).selected = true
    select.dispatchEvent(new Event('change'))
    expect(labelTexts()).toEqual(['Collection One', 'Collection Two'])

    select.querySelector(`option[value="${COLLECTION_ONE}"]`).selected = false
    select.dispatchEvent(new Event('change'))
    expect(labelTexts()).toEqual(['Collection Two'])
  })

  it('keeps a box checked when the collection list is rebuilt', () => {
    const { element, select } = buildForm({
      options: [{ id: COLLECTION_ONE, label: 'Collection One' }],
      selectedCollections: [COLLECTION_ONE]
    })

    new FeaturableCollections(element)
    renderedCheckboxes()[0].click()

    select.querySelector(`option[value="${COLLECTION_TWO}"]`).selected = true
    select.dispatchEvent(new Event('change'))

    expect(renderedCheckboxes().map((input) => input.checked)).toEqual([true, false])
  })

  it('explains why there is nothing to highlight when there are no options', () => {
    const { element } = buildForm()

    new FeaturableCollections(element)

    expect(renderedCheckboxes()).toEqual([])
    expect(document.querySelector('.featurable-collections-empty').textContent).toEqual(
      'Add this resource to a collection.'
    )
  })

  it('falls back to the change set list when the form has no collections select', () => {
    const { element } = buildForm({
      options: [{ id: COLLECTION_ONE, label: 'Collection One' }],
      selected: [COLLECTION_ONE]
    })
    document.querySelector('.member-of-collection-ids').remove()

    new FeaturableCollections(element)

    expect(labelTexts()).toEqual(['Collection One'])
    expect(renderedCheckboxes()[0].checked).toBe(true)
  })

  it('ignores unmigrated boolean values that are still stored as featurable', () => {
    const { element } = buildForm({
      selected: ['1'],
      options: [{ id: COLLECTION_ONE, label: 'Collection One' }],
      selectedCollections: [COLLECTION_ONE]
    })

    new FeaturableCollections(element)

    expect(renderedCheckboxes().map((input) => input.value)).toEqual([COLLECTION_ONE])
    expect(renderedCheckboxes()[0].checked).toBe(false)
  })
})
