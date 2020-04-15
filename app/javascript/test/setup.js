import Vue from 'vue'
import _ from 'lodash'

Vue.config.productionTip = false
jest.unmock('lodash')
_.debounce = jest.fn((fn) => fn);
