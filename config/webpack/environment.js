const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')

environment.plugins.append('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.append('vue', vue)
environment.loaders.append('eslint', {
  enforce: 'pre',
  test: /\.vue$/,
  use: [{ loader: 'eslint-loader' }]
})

module.exports = environment
