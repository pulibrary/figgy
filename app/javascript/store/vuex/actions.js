// actions
import axios from 'axios'
import manifesto from 'manifesto.js'
import mixins from '../../mixins/manifesto-filemanager-mixins'
import Pluralize from 'pluralize'
import apollo from '../../helpers/apolloClient'
import gql from 'graphql-tag'

function MutationBuilder(resource, filesets) {
  this.filesetNum = filesets.length
  this.query_template = 'mutation UpdateResource(__inputs__: UpdateResourceInput!) { __mutations__ }'
  this.inputs = function() {
    let inputs = ['$input']
    for (let i=0; i < this.filesetNum; i++ ) {
      inputs.push('$fileset_' + i)
    }
    return inputs
  }
  this.mutations = function() {
    let mutations = []
    let mutation_template = '__mname__: updateResource(input: $__mname__) { resource { id, thumbnail { id, iiifServiceUrl, thumbnailUrl }, ... on ScannedResource { startPage, viewingHint, viewingDirection, members { id, label, thumbnail { id, thumbnailUrl, iiifServiceUrl } } } }, errors }'
    let inputs = this.inputs()
    let mutationNum = inputs.length
    for (let i=0; i < mutationNum; i++ ) {
      mutations.push(mutation_template.replace(/__mname__/g, inputs[i]).substr(1))
    }
    return mutations
  }
  this.variables = function() {
    let variables = {}
    variables.input = resource
    for (let i=0; i < this.filesetNum; i++ ) {
      variables['fileset_' + i] = filesets[i]
    }
    return variables
  }
  this.build = function() {
      let request = this.query_template.replace('__inputs__', this.inputs().join(': UpdateResourceInput!,'))
      return request.replace('__mutations__', this.mutations().join())
  }
}

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
             thumbnail {
               id,
               thumbnailUrl,
               iiifServiceUrl
             },
             ... on ScannedResource {
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
      console.log(response.data.updateResource.resource)
      context.commit('SET_RESOURCE', response.data.updateResource.resource)
    } catch(err) {
      console.error(err)
    }

    // const mutation = gql`
    //   mutation UpdateResource($input: UpdateResourceInput!) {
    //     updateResource(input: $input) {
    //       resource {
    //         id,
    //         thumbnail {
    //           id,
    //           iiifServiceUrl,
    //           thumbnailUrl
    //         },
    //         ... on ScannedResource {
    //           startPage,
    //           viewingHint,
    //           viewingDirection,
    //           members {
    //             id,
    //             label,
    //             thumbnail {
    //              id,
    //              thumbnailUrl,
    //              iiifServiceUrl
    //             },
    //             viewingHint
    //           }
    //         }
    //       },
    //       errors
    //       }
    //     }`

    //   const filesetMutation = gql`
    //     mutation UpdateResource($input: UpdateResourceInput!) {
    //       updateResource(input: $input) {
    //         resource {
    //           id,
    //           label,
    //           ... on ScannedResource {
    //             viewingHint
    //           }
    //         },
    //         errors
    //         }
    //       }`
        // mutation UpdateResource($input: UpdateResourceInput!, $fileset: UpdateResourceInput!) {
        //   one: updateResource(input: $input) {
        //     resource {
        //       id,
        //       thumbnail {
        //         id,
        //         iiifServiceUrl,
        //         thumbnailUrl
        //       },
        //       ... on ScannedResource {
        //         startPage,
        //         viewingHint,
        //         viewingDirection,
        //         members {
        //           id,
        //           label,
        //           thumbnail {
        //            id,
        //            thumbnailUrl,
        //            iiifServiceUrl
        //           }
        //         }
        //       }
        //     },
        //     errors
        //   },
        //   two: updateResource(input: $fileset) {
        //     resource {
        //       id,
        //       thumbnail {
        //         id,
        //         iiifServiceUrl,
        //         thumbnailUrl
        //       },
        //       ... on ScannedResource {
        //         startPage,
        //         viewingHint,
        //         viewingDirection,
        //         members {
        //           id,
        //           label,
        //           thumbnail {
        //            id,
        //            thumbnailUrl,
        //            iiifServiceUrl
        //           }
        //         }
        //       }
        //     },
        //     errors
        //   }
        // }

        // {
        //     "one": {
        //         "id": "4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d",
        //         "viewingDirection": "LEFTTORIGHT",
        //         "viewingHint": "paged",
        //         "startPage": "291b467b-36af-4d1e-80f1-dc76e8e250b9",
        //         "thumbnailId": "c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab",
        //         "memberIds": ["acb1c188-57c4-41cb-88e0-f44aca12e565", "c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab", "291b467b-36af-4d1e-80f1-dc76e8e250b9"]
        //     },
        //     "two": {
        //         "id": "acb1c188-57c4-41cb-88e0-f44aca12e565",
        //         "label": "p. i",
        //         "viewingHint": "facing"
        //     }
        // }

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
