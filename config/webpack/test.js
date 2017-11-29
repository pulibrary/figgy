// const merge = require('webpack-merge')
// const environment = require('./environment')
// const customConfig = require('./custom')
//
// module.exports = merge(environment.toWebpackConfig(), customConfig)

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
