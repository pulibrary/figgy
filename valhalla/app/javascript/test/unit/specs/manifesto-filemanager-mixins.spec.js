import manifesto from 'manifesto.js'
import mixins from '@/mixins/manifesto-filemanager-mixins'
import manifest from '@/test/fixtures/manifest'

describe('mixins', () => {
  const manifestation = Object.assign(manifesto.create(JSON.stringify(manifest)), mixins)

  it('ImageCollection', () => {
    const resource = {"id":"9a25e0ce-4f64-4995-bae5-29140a453fa3","class_name":"ephemera_folders"}
    const ic = manifestation.imageCollection(resource)
    expect(ic.id).toBe('9a25e0ce-4f64-4995-bae5-29140a453fa3')
    expect(ic.viewingDirection).toBe('left-to-right')
    expect(ic.images[0].label).toBe('foo')
  })

  it('ImageCollection', () => {
    const resource = {"id":"9a25e0ce-4f64-4995-bae5-29140a453fa3","class_name":"ephemera_folders"}
    const ic = manifestation.imageCollection(resource)
    expect(ic.id).toBe('9a25e0ce-4f64-4995-bae5-29140a453fa3')
    expect(ic.viewingDirection).toBe('left-to-right')
    expect(ic.images[0].label).toBe('foo')
  })

  it('mainSequence', () => {
    const resource = {"id":"9a25e0ce-4f64-4995-bae5-29140a453fa3","class_name":"ephemera_folders"}
    const seq = manifestation.mainSequence()
    expect(seq.id).toBe('bar')
  })

  it('getCanvasMainThumb', () => {
    const s = manifestation.mainSequence()
    const canvases = s.getCanvases()
    const thumb = manifestation.getCanvasMainThumb(canvases[1])
    expect(thumb).toBe('http://localhost:3000/image-service/50b5e49b-ade7-4278-8265-4f72081f26a5/full/400,/0/default.jpg')
  })

  it('getResourceId', () => {
    const s = manifestation.mainSequence()
    const canvases = s.getCanvases()
    const resource = manifestation.getResourceId(canvases[1])
    expect(resource).toBe('50b5e49b-ade7-4278-8265-4f72081f26a5')
  })

  it('getEnglishLabel', () => {
    const s = manifestation.mainSequence()
    const canvases = s.getCanvases()
    const label = manifestation.getEnglishLabel(canvases[1])
    expect(label).toBe('[p. i (verso)]')
  })

  it('getThumbnailId', () => {
    const t = manifestation.getThumbnailId()
    expect(t).toBe('80b02791-4bd9-4566-9a9f-4b3062ba2e0d')
  })

})
