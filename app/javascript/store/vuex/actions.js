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
      context.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADED')
    } catch (err) {
      context.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADING_ERROR')
      context.commit('ERROR_MESSAGE', err)
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
        context.commit('APPLY_STATE')
      })
      .catch((err) => {
        context.commit('ERROR_MESSAGE', err)
        context.commit('SAVED_STATE', 'ERROR')
      })
  },
  async saveStructureAJAX (context, resource) {
    context.commit('SAVED_STRUCTURE_STATE', 'SAVING')

    let resource_type = resource.resourceClassName.replace(/([a-z])([A-Z])/g, '$1_$2').toLowerCase()

    let xhr = new XMLHttpRequest()
    let url = `/concern/${resource_type}s/${resource.id}`
    let data = JSON.stringify({[resource_type]: {'logical_structure': [resource.structure] }})
    let token = document.querySelector('meta[name="csrf-token"]').content
    console.log(token)
    xhr.open('PUT', url, true)
    xhr.setRequestHeader('Content-Type', 'application/json')
    xhr.setRequestHeader('dataType', 'json')
    xhr.setRequestHeader('X-CSRF-Token', token)

    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4) {
        // Request completed
        console.log('Request Completed!')
        if (xhr.status === 200 || xhr.status === 201) {
          // Successful response
          console.log('Successful Save!')
          context.commit('SAVED_STRUCTURE_STATE', 'SAVED');
          context.commit('APPLY_TREE_STATE');
        } else {
          // Handle errors here
          console.error('Error:', xhr.status, xhr.statusText);
          context.commit('SAVED_STRUCTURE_STATE', 'ERROR')
        }
      }
    };

    xhr.send(data);

  }
}

export default actions
