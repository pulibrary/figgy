import Vue from 'vue'
import _ from 'lodash'
import VueDetails from 'vue-details'

Vue.config.productionTip = false
Vue.component('v-details', VueDetails)
jest.unmock('lodash')
_.debounce = jest.fn((fn) => fn);
