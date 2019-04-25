require('dotenv').config()
const checkFixity = require('..').checkFixity
const fs = require('fs')
// Mock Cloud Storage
const { Storage } = require('@google-cloud/storage')
jest.mock('@google-cloud/storage')
const file = jest.fn(name => ({
  createReadStream: () => {
    return fs.createReadStream(`test/fixtures/${name}`)
  }
}))
const bucket = jest.fn(() => ({ file }))
Storage.mockImplementation(() => ({ bucket }))
// Mock PubSub
const { PubSub } = require('@google-cloud/pubsub')
jest.mock('@google-cloud/pubsub')
const publishJSON = jest.fn(() => {
  return new Promise((resolve, reject) => { resolve() })
})
const topic = jest.fn(name => ({
  publishJSON }))
PubSub.mockImplementation(() => ({ topic }))

test(`succeeds when given a good MD5`, async () => {
  const attributes = {
    preservation_object_id: '1',
    file_metadata_node_id: '1',
    cloudPath: 'example.tif',
    md5: '2a28fb702286782b2cbf2ed9a5041ab1',
    child_property: 'bla'
  }
  const event = {
    data: Buffer.from(JSON.stringify(attributes)).toString('base64')
  }
  await checkFixity(event)
  expect(publishJSON).toBeCalledWith({
    status: 'SUCCESS',
    resource_id: '1',
    child_id: '1',
    child_property: 'bla'
  })
})

test(`fails when given a bad MD5`, async () => {
  const attributes = {
    preservation_object_id: '1',
    file_metadata_node_id: '1',
    cloudPath: 'example.tif',
    md5: '123',
    child_property: 'bla'
  }
  const event = {
    data: Buffer.from(JSON.stringify(attributes)).toString('base64')
  }
  await checkFixity(event)
  expect(publishJSON).toBeCalledWith({
    status: 'FAILURE',
    resource_id: '1',
    child_id: '1',
    child_property: 'bla'
  })
})
