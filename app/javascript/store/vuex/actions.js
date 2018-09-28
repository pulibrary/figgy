// actions
import apollo from '../../helpers/apolloClient'
import MutationBuilder from '../../helpers/mutationBuilder'
import gql from 'graphql-tag'

const actions = {
  async loadImageCollectionGql (context, resource) {
      if (resource == null) {
        context.commit('CHANGE_MANIFEST_LOAD_STATE', 'LOADING_ERROR')
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
      } catch(err) {
        context.commit('CHANGE_MANIFEST_LOAD_STATE', 'LOADING_ERROR')
        console.error(err)
      }

      console.timeEnd(`getResourceById ${resource.id}`)

  },
  async saveStateGql (context, resource) {
    window.resource = resource
    let newResource = resource.body
    let newFilesets = resource.filesets

    let mb = new MutationBuilder(newResource, newFilesets)

    const template = mb.build()
    const mutation = gql`${template}`
    const variables = mb.variables()

    try {
      const response = await apollo.mutate({
        mutation, variables
      })
      // reset the state to reflect applied changes
      context.commit('SAVED_STATE', 'SAVED')
      setTimeout(function(){ context.commit('APPLY_STATE') }, 1000);
    } catch(err) {
      context.commit('SAVED_STATE', 'ERROR')
      console.error(err)
    }
  },
}

export default actions
