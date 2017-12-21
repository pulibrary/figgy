import getters from '@/store/vuex/getters'
import state from '@/store/vuex/state'
import Fixtures from '@/test/fixtures/image-collection'

describe('getters', () => {
  it('imageIdList', () => {
    // mock state
    const locState = { images : Fixtures.imageCollection }
     // get the result from the getter
    const result = getters.imageIdList(locState)
    // assert result
    expect(result).toEqual(['50b5e49b-ade7-4278-8265-4f72081f26a5','dae7619f-16a7-4306-93e4-70b4b192955c'])
  })

  it('orderChanged', () => {
    // mock state from import
    // apply mutation
    const locState1 = { images : Fixtures.imageCollection,
                       ogImages : Fixtures.imageCollection}

    let changed = getters.orderChanged(locState1)
    // assert result
    expect(changed).toBe(false)

    const locState2 = { images : Fixtures.sortedImages,
                       ogImages : Fixtures.imageCollection}

    changed = getters.orderChanged(locState2)
    // assert result
    expect(changed).toBe(true)
  })

  it('stateChanged', () => {
    // mock state
    const locState = {
                       thumbnail: Fixtures.initState.thumbnail,
                       startPage: Fixtures.initState.startPage,
                       viewingHint: Fixtures.initState.viewingHint,
                       viewingDirection: Fixtures.initState.viewingDirection,
                       changeList: [],
                       ogState: {  startPage: Fixtures.initState.startPage,
                                   thumbnail: Fixtures.initState.thumbnail,
                                   viewingHint: Fixtures.initState.viewingHint,
                                   viewingDirection: Fixtures.initState.viewingDirection
                                 }
                     }
     // get the result from the getter
    const result1 = getters.stateChanged(locState,getters)
    // assert result
    expect(result1).toBe(false)
    // change and assert second result
    locState.thumbnail = "foo"
    const result2 = getters.stateChanged(locState,getters)
    expect(result2).toBe(true)

  })

})
