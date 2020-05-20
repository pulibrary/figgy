const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')
const dotenv = require('dotenv')

const dotenvFiles = [
  `.env.${process.env.NODE_ENV}.local`,
  '.env.local',
  `.env.${process.env.NODE_ENV}`,
  '.env'
]

dotenvFiles.forEach((dotenvFile) => {
  dotenv.config({ path: dotenvFile, silent: true })
})

environment.plugins.append('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.append('vue', vue)
environment.loaders.append('eslint', {
  enforce: 'pre',
  test: /\.vue$/,
  use: [{ loader: 'eslint-loader' }]
})

module.exports = environment
