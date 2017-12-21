// actions
import axios from 'axios'
import manifesto from 'manifesto.js'
import mixins from '../../mixins/manifesto-filemanager-mixins'
import Pluralize from 'pluralize'

const actions = {
  loadImageCollection (context, resource) {
    const manifest_uri = '/concern/'+ resource.class_name + '/' + resource.id + '/manifest'
    return axios.get(manifest_uri).then((response) => {
      const manifestation = Object.assign(manifesto.create(JSON.stringify(response.data)), mixins)
      window.manifestation = manifestation
      context.commit('SET_STATE', manifestation.imageCollection(resource) )
    }, (err) => {
      console.log(err)
    })
  },
  handleSelect (context, imgArray) {
    context.commit('SELECT', imgArray)
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
    let file_set_promises = []
    for (let i = 0; i < body.file_sets.length; i++) {
      file_set_promises.push(axios.patch('/concern/file_sets/' + body.file_sets[i].id, body.file_sets[i]))
    }
    let resourceClassNames = Object.keys(body.resource)
    return axios.patch('/concern/' + Pluralize.plural(resourceClassNames[0]) + '/' + body.resource[resourceClassNames[0]].id, body.resource)
      .then((response) => {
        return axios.all(file_set_promises)
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
