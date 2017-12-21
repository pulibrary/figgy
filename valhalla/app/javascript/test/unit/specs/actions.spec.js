import actions from '@/store/vuex/actions'
import { body } from '@/test/fixtures/image-collection'

jest.mock('axios')

describe('actions', () => {
  it('loadImageCollection', () => {
    let data
    let resource = {"id":"9a25e0ce-4f64-4995-bae5-29140a453fa3","class_name":"ephemera_folders"}
    let mockCommit = (state, payload) => {
      data = payload
    }
    actions.loadImageCollection({ commit: mockCommit }, resource)
      .then(() => {
         expect(data.id).toBe('9a25e0ce-4f64-4995-bae5-29140a453fa3')
         expect(data.images.length).toBe(6)
      })
      .catch(
      (error) => {
        console.log(error);
      }
    )
  })

  it('saveState', () => {
    let data

    let mockCommit = (state, payload) => {
      data = payload
    }
    actions.saveState({ commit: mockCommit }, body)
      .then(() => {
         // should reset state
         expect(data).toEqual([])
      }).catch(
      (error) => {
        console.log(error);
      })
  })
})
