import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex'
import axios from 'axios'
import manifesto from 'manifesto.js'
import mixins from '../mixins/manifesto-filemanager-mixins'
import Pluralize from 'pluralize'

Vue.use(Vuex)

const state = {
  id: '',
  resourceClassName: '',
  startPage: '',
  thumbnail: '',
  viewingDirection: '',
  viewingHint: '',
  images: [],
  selected: [],
  ogImages: [],
  changeList: [],
  ogState: {}
}

const mutations = {
  SELECT (state, imgArray) {
    state.selected = imgArray
  },
  SET_STATE (state, ImageCollection) {
    state.id = ImageCollection.id
    state.resourceClassName = ImageCollection.resourceClassName
    state.startPage = ImageCollection.startpage
    state.thumbnail = ImageCollection.thumbnail
    state.viewingHint = ImageCollection.viewingHint
    state.viewingDirection = ImageCollection.viewingDirection
    state.images = ImageCollection.images
    state.ogImages = ImageCollection.images
    state.ogState = { startPage: ImageCollection.startpage,
                      thumbnail: ImageCollection.thumbnail,
                      viewingHint: ImageCollection.viewingHint,
                      viewingDirection: ImageCollection.viewingDirection
                    }
  },
  SAVE_STATE (state, reset) {
    flash('State saved!', 'success')
    state.ogImages = [ ...state.images ]
    state.changeList = [ ...reset ]
    state.selected = [ ...reset ]
  },
  SORT_IMAGES (state, value) {
    state.images = [ ...value ]
  },
  UPDATE_CHANGES (state, changeList) {
    state.changeList = [ ...changeList ]
  },
  UPDATE_IMAGES (state, images) {
    state.images = [ ...images ]
  },
  UPDATE_STARTPAGE (state, startPage) {
    state.startPage = startPage
  },
  UPDATE_THUMBNAIL (state, thumbnail) {
    state.thumbnail = thumbnail
  },
  UPDATE_VIEWDIR (state, viewDir) {
    state.viewingDirection = viewDir
  },
  UPDATE_VIEWHINT (state, viewHint) {
    state.viewingHint = viewHint
  }
}

const actions = {
  incrementAsync ({ commit }) {
    setTimeout(() => {
      commit('INCREMENT')
    }, 200)
  },
  loadImageCollection (context, resource) {
    const manifest_uri = '/concern/'+ resource.class_name + '/' + resource.id + '/manifest'
    axios.get(manifest_uri).then((response) => {
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
    let token = document.getElementsByName('csrf-token')[0].getAttribute('content')

    axios.defaults.headers.common['X-CSRF-Token'] = token
    axios.defaults.headers.common['Accept'] = 'application/json'

    let file_set_promises = []
    for (let i = 0; i < body.file_sets.length; i++) {
      file_set_promises.push(axios.patch('/concern/file_sets/' + body.file_sets[i].id, body.file_sets[i]))
    }
    let resourceClassNames = Object.keys(body.resource)
    axios.patch('/concern/' + Pluralize.plural(resourceClassNames[0]) + '/' + body.resource[resourceClassNames[0]].id, body.resource).then((response) => {
      axios.all(file_set_promises).then(axios.spread((...args) => {
        context.commit('SAVE_STATE', [])
      }, (err) => {
        alert(errors.join('\n'))
      }))
    }, (err) => {
      alert(errors.join('\n'))
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

const getters = {
  imageIdList: state => {
    return state.images.map(image => image.id)
  },
  orderChanged: state => {
    var ogOrder = JSON.stringify(state.ogImages.map(img => img.id))
    var imgOrder = JSON.stringify(state.images.map(img => img.id))
    return ogOrder !== imgOrder
  },
  stateChanged: (state,getters) => {
    var propsChanged = []
    propsChanged.push(state.ogState.thumbnail !== state.thumbnail)
    propsChanged.push(state.ogState.startPage !== state.startPage)
    propsChanged.push(state.ogState.viewingHint !== state.viewingHint)
    propsChanged.push(state.ogState.viewingDirection !== state.viewingDirection)
    propsChanged.push(state.changeList.length > 0)
    propsChanged.push(getters.orderChanged)
    if (propsChanged.indexOf(true) > -1) {
      return true
    } else {
      return false
    }
  }
}

const store = new Vuex.Store({
  state,
  mutations,
  actions,
  getters
})

export default store
