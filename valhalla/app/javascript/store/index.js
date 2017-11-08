import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex'
import state from './vuex/state'
import mutations from './vuex/mutations'
import actions from './vuex/actions'
import getters from './vuex/getters'

Vue.use(Vuex)

const store = new Vuex.Store({
  state,
  mutations,
  actions,
  getters
})

export default store
