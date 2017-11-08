import mutations from '@/store/vuex/mutations'
import state from '@/store/vuex/state'
import Fixtures from '@/test/fixtures/image-collection'

describe('mutations', () => {
  it('SELECT', () => {
    // mock state
    const locState = { selected : [] }
    // apply mutation
    mutations.SELECT(locState, Fixtures.imageCollection)
    // assert result
    expect(locState.selected.length).toBe(2)
  })

  it('SET_STATE', () => {
    // mock state from import
    // apply mutation
    mutations.SET_STATE(state, Fixtures.initState)
    // assert result
    expect(state.id).toBe('9a25e0ce-4f64-4995-bae5-29140a453fa3')
  })

  it('SORT_IMAGES', () => {
    const locState = { images : Fixtures.imageCollection }
    mutations.SORT_IMAGES(locState, Fixtures.sortedImages)
    expect(locState.images[0].label).toBe('foo')
  })

  it('UPDATE_CHANGES', () => {
    const locState = { changeList : [] }
    mutations.UPDATE_CHANGES(locState, Fixtures.changeList)
    expect(locState.changeList.length).toBe(1)
  })

  it('UPDATE_IMAGES', () => {
    const locState = { images : Fixtures.sortedImages }
    mutations.UPDATE_IMAGES(locState, Fixtures.imageCollection)
    expect(locState.images[0].label).toBe('baz')
  })

  it('UPDATE_STARTPAGE', () => {
    const locState = { startPage : Fixtures.startPage }
    mutations.UPDATE_STARTPAGE(locState, 'bar')
    expect(locState.startPage).toBe('bar')
  })

  it('UPDATE_THUMBNAIL', () => {
    const locState = { thumbnail : Fixtures.thumbnail }
    mutations.UPDATE_THUMBNAIL(locState, 'fee')
    expect(locState.thumbnail).toBe('fee')
  })

  it('UPDATE_VIEWDIR', () => {
    const locState = { viewingDirection : Fixtures.initState.viewingDirection }
    mutations.UPDATE_VIEWDIR(locState, 'right-to-left')
    expect(locState.viewingDirection).toBe('right-to-left')
  })

  it('UPDATE_VIEWHINT', () => {
    const locState = { viewingHint : Fixtures.initState.viewingHint }
    mutations.UPDATE_VIEWHINT(locState, 'continuous')
    expect(locState.viewingHint).toBe('continuous')
  })

})
