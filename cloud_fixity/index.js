const { Storage } = require('@google-cloud/storage')
const { PubSub } = require('@google-cloud/pubsub')
const crypto = require('crypto')

exports.checkFixity = (data, context) => {
  const attributes = JSON.parse(Buffer.from(data.data, 'base64').toString())
  const md5 = attributes.md5
  const cloudPath = attributes.cloudPath
  const storage = new Storage()
  const bucket = storage.bucket(process.env.BUCKET || 'figgy-staging-preservation')
  const file = bucket.file(cloudPath)
  const fd = file.createReadStream()
  const hash = crypto.createHash('md5')
  const pubsub = new PubSub()
  const topic = pubsub.topic(process.env.FIXITY_STATUS_TOPIC || 'figgy-staging-fixity-status')
  const requestTopic = pubsub.topic(process.env.FIXITY_REQUEST_TOPIC || 'figgy-staging-fixity-request')
  hash.setEncoding('hex')

  // read all file and pipe it (write it) to the hash object
  var compute = new Promise(function (resolve, reject) {
    fd.on('end', function () {
      hash.end()
      resolve(hash.read())
    })
    fd.on('error', (err) => {
      reject('there was a stream error; re-queing')
    })
    fd.pipe(hash)
  })

  // Compare MD5 with value
  return compute.then((result) => {
    var promise = null
    if (result === md5) {
      promise = topic.publishJSON({
        status: 'SUCCESS',
        resource_id: attributes.preservation_object_id,
        child_id: attributes.file_metadata_node_id,
        child_property: attributes.child_property
      })
    } else {
      promise = topic.publishJSON({
        status: 'FAILURE',
        resource_id: attributes.preservation_object_id,
        child_id: attributes.file_metadata_node_id,
        child_property: attributes.child_property
      })
    }
    return promise
  }).catch((err) => {
    attributes['retry_count'] = (attributes['retry_count'] || 0) + 1
    if(attributes['retry_count'] >= 5) {
      return topic.publishJSON({
        status: 'FAILURE',
        resource_id: attributes.preservation_object_id,
        child_id: attributes.file_metadata_node_id,
        child_property: attributes.child_property
      })
    } else {
      return requestTopic.publishJSON(attributes)
    }
  })
}
