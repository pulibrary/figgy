import { mount, shallowMount } from "@vue/test-utils"
import ImageCropper from "../components/ImageCropper.vue"
import OpenSeadragon from 'openseadragon'

let wrapper
let options

describe("ImageCropper.vue", () => {
  beforeEach(() => {
    wrapper = mount(ImageCropper, {
      global: {
        options,
        // stubs: ["heading","input-radio","text-style"],
      }
    })

    // We don't want to actually run the initialization, we're just here to test
    // a function
    vi.spyOn(wrapper.vm, 'initOSD').mockImplementation(() => null)
  })

  it('parses an info.json url', () => {
    // expect(wrapper.vm.parseUrl('https://iiif-cloud.princeton.edu/iiif/2/60%2Fb5%2Fe5%2F60b5e5365600450db52dbe4d7f92b8cc%2Fintermediate_file/642,2316,3854,2569/full/0/default.jpg'))
    expect(
      wrapper.vm.parseUrl('https://iiif-cloud.princeton.edu/iiif/2/60%2Fb5%2Fe5%2F60b5e5365600450db52dbe4d7f92b8cc%2Fintermediate_file/info.json')
    ).toEqual(
      {
        "infoUrl": "https://iiif-cloud.princeton.edu/iiif/2/60%2Fb5%2Fe5%2F60b5e5365600450db52dbe4d7f92b8cc%2Fintermediate_file/info.json",
        "savedRegion": null,
      })
  })

  it('parses a full IIIF image api url', () => {
    expect(
      wrapper.vm.parseUrl('https://iiif-cloud.princeton.edu/iiif/2/74%2Fea%2Fee%2F74eaee0426ab49a6923dd6bcc401a334%2Fintermediate_file/full/full/0/default.jpg')
    ).toEqual(
      {
        "infoUrl": "https://iiif-cloud.princeton.edu/iiif/2/74%2Fea%2Fee%2F74eaee0426ab49a6923dd6bcc401a334%2Fintermediate_file/info.json",
        "savedRegion": null,
      })
  })

  it('parses a cropped IIIF image api url', () => {
    expect(
      wrapper.vm.parseUrl('https://iiif-cloud.princeton.edu/iiif/2/74%2Fea%2Fee%2F74eaee0426ab49a6923dd6bcc401a334%2Fintermediate_file/266,869,1598,1066/full/0/default.jpg')
    ).toEqual(
      {
        "infoUrl": "https://iiif-cloud.princeton.edu/iiif/2/74%2Fea%2Fee%2F74eaee0426ab49a6923dd6bcc401a334%2Fintermediate_file/info.json",
        "savedRegion": { "h": 1066, "w": 1598, "x": 266, "y": 869 }
      })
  })
})
