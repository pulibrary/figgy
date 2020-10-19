// actions
import apollo from '../../helpers/apolloClient'
import MutationBuilder from '../../helpers/mutationBuilder'
import gql from 'graphql-tag'

const actions = {
  cut (context, items) {
    context.commit('CUT', items)
  },
  paste (context, items) {
    context.commit('PASTE', items)
  },
  select (context, selectList) {
    context.commit('SELECT', selectList)
  },
  updateChanges (context, changeList) {
    context.commit('UPDATE_CHANGES', changeList)
  },
  updateItems (context, items) {
    context.commit('UPDATE_ITEMS', items)
  },
  updateStartCanvas (context, startCanvas) {
    context.commit('UPDATE_STARTCANVAS', startCanvas)
  },
  updateThumbnail (context, thumbnail) {
    context.commit('UPDATE_THUMBNAIL', thumbnail)
  },
  updateViewHint (context, value) {
    context.commit('UPDATE_VIEWHINT', value)
  },
  updateViewDir (context, value) {
    context.commit('UPDATE_VIEWDIR', value)
  },
  async loadImageCollectionGql (context, resource) {
    if (resource == null) {
      context.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADING_ERROR')
      console.error('Failed to retrieve the resource')
      return
    }

    let id = resource.id
    console.time(`getResourceById ${id}`)

    const query = gql`
        query GetResource($id: ID!) {
          resource(id: $id) {
             id,
             label,
             viewingHint,
             thumbnail {
               id,
               thumbnailUrl,
               iiifServiceUrl
             },
             ... on ScannedResource {
               viewingDirection,
               startPage
             },
             ... on ScannedMap {
               viewingDirection,
               startPage
             },
             __typename,
             members {
               id,
               label,
               thumbnail {
                id,
               	thumbnailUrl,
                iiifServiceUrl
               },
               viewingHint,
               __typename
             }
          }
        }`

    const variables = {
      id: id
    }

    try {
      const response = await apollo.query({
        query, variables
      })
      context.commit('SET_RESOURCE', response.data.resource)
    } catch (err) {
      context.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADING_ERROR')
      console.error(err)
    }

    console.timeEnd(`getResourceById ${resource.id}`)
  },
  async saveStateGql (context, resource) {
    context.commit('SAVED_STATE', 'SAVING')
    let newResource = resource.body
    let newFilesets = resource.filesets

    let mb = new MutationBuilder(newResource, newFilesets)

    const template = mb.build()
    const mutation = gql`${template}`
    const variables = mb.variables()
    return apollo.mutate({ mutation, variables })
      .then(() => {
        context.commit('SAVED_STATE', 'SAVED')
        context.commit('APPLY_STATE', 1000)
      })
      .catch((err) => {
        console.error(err)
        context.commit('SAVED_STATE', 'ERROR')
      })
  }
}

export default actions
