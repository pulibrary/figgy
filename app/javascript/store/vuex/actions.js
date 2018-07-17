// actions
import axios from 'axios'
import manifesto from 'manifesto.js'
import mixins from '../../mixins/manifesto-filemanager-mixins'
import Pluralize from 'pluralize'
import apollo from '../../helpers/apolloClient'
import gql from 'graphql-tag'

const actions = {
  async loadImageCollectionGql (context, resource) {
      let id = resource.id
      console.time(`getResourceById ${id}`)

      const query = gql`
        query GetResource($id: ID!) {
          resource(id: $id) {
             id,
             label,
             viewingHint,
             ... on ScannedResource {
               viewingDirection
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
  loadImageCollection (context, resource) {
    const manifest_uri = '/concern/'+ resource.class_name + '/' + resource.id + '/manifest'
    return axios.get(manifest_uri).then((response) => {
      const manifestation = Object.assign(manifesto.create(JSON.stringify(response.data)), mixins)
      window.manifestation = manifestation
      context.commit('CHANGE_MANIFEST_LOAD_STATE', 'LOADED')
      context.commit('SET_STATE', manifestation.imageCollection(resource))
    }, (err) => {
      context.commit('CHANGE_MANIFEST_LOAD_STATE', 'LOADING_ERROR')
      console.log(err)
    })
  },
  changeManifestLoadState (context, loadState) {
    context.commit('CHANGE_MANIFEST_LOAD_STATE', loadState)
  },
  handleSelect (context, imgArray) {
    context.commit('SELECT', imgArray)
  },
  handleCut (context, imgArray) {
    context.commit('CUT', imgArray)
  },
  handlePaste (context, imgArray) {
    context.commit('PASTE', imgArray)
  },
  async saveStateGql (context, resource) {
    window.resource = resource
    let newResource = resource

    const mutation = gql`
      mutation UpdateResource($input: UpdateResourceInput!) {
        updateResource(input: $input) {
          resource {
            id,
            thumbnail {
              id,
              iiifServiceUrl,
              thumbnailUrl
            },
            ... on ScannedResource {
              startPage,
              viewingHint,
              viewingDirection,
              members {
                id,
                label,
                thumbnail {
                 id,
                 thumbnailUrl,
                 iiifServiceUrl
                },
                viewingHint
              }
            }
          },
          errors
          }
        }`

    const variables = {
      input: newResource
    }

    try {
      const response = await apollo.mutate({
        mutation, variables
      })
      console.log(response.data.updateResource.resource)
      context.commit('SET_RESOURCE', response.data.updateResource.resource)
    } catch(err) {
      // context.commit('CHANGE_MANIFEST_LOAD_STATE', 'LOADING_ERROR')
      console.error(err)
    }

  },
  saveState (context, body) {
    window.body = body
    let errors = []
    let token
    if (!document.getElementsByName('csrf-token')[0]){
      // token needs some value for tests that do not have a real DOM
      token = 'stub'
    } else {
      token = document.getElementsByName('csrf-token')[0].getAttribute('content')
    }

    axios.defaults.headers.common['X-CSRF-Token'] = token
    axios.defaults.headers.common['Accept'] = 'application/json'
    let member_promises = []
    if(body.hasOwnProperty('file_sets')){
      for (let i = 0; i < body.file_sets.length; i++) {
        member_promises.push(axios.patch('/concern/file_sets/' + body.file_sets[i].id, body.file_sets[i]))
      }
    } else {
      for (let i = 0; i < body.volumes.length; i++) {
        member_promises.push(axios.patch('/concern/scanned_resources/' + body.volumes[i].id, body.volumes[i]))
      }
    }
    let resourceClassNames = Object.keys(body.resource)
    return axios.patch('/concern/' + Pluralize.plural(resourceClassNames[0]) + '/' + body.resource[resourceClassNames[0]].id, body.resource)
      .then((response) => {
        return axios.all(member_promises)
          .then(([...args]) => {
            context.commit('SAVE_STATE', [])
          }).catch(
            (error) => {
              console.log(error);
            })
      }).catch(
        (error) => {
          console.log(error);
        })
  },
  sortImages (context, value) {
    context.commit('SORT_IMAGES', value)
  },
  updateChanges (context, changeList) {
    context.commit('UPDATE_CHANGES', changeList)
  },
  updateImages (context, images) {
    context.commit('UPDATE_IMAGES', images)
  },
  updateStartPage (context, startPage) {
    context.commit('UPDATE_STARTPAGE', startPage)
  },
  updateThumbnail (context, thumbnail) {
    context.commit('UPDATE_THUMBNAIL', thumbnail)
  },
  updateViewDir (context, viewDir) {
    context.commit('UPDATE_VIEWDIR', viewDir)
  },
  updateViewHint (context, viewHint) {
    context.commit('UPDATE_VIEWHINT', viewHint)
  }
}

export default actions
