import { createStore } from "vuex"
import { mount, shallowMount } from "@vue/test-utils"
import OrderManager from "../components/OrderManager.vue"
import { resourceMutations, resourceGetters } from "../store/resource"
import { galleryModule } from '../store/gallery'

// Work-around in order to ensure that the Global object is accessible from the component
const Global = {
  figgy: {
    resource: {
      defaultThumbnail: "https://institution.edu/repository/assets/random.png"
    }
  }
}
window.Global = Global

let wrapper
let items = [
  { id: "a", title: "A", caption: "a", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "b", title: "B", caption: "b", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "c", title: "C", caption: "c", mediaUrl: "https://picsum.photos/600/300/?random" },
]
let resourceObject = {
  id: "aea40813-e0ed-4307-aae9-aec53b26bdda",
  label: "Resource with 3 files",
  viewingHint: "individuals",
  viewingDirection: "LEFTTORIGHT",
  startPage: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
  thumbnail: {
    id: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
    thumbnailUrl:
      "http://localhost:3000/image-service/8ffd7a03-ec0e-46c1-a347-e4b19cb7839f/full/!200,150/0/default.jpg",
    iiifServiceUrl: "http://localhost:3000/image-service/8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
  },
  __typename: "ScannedResource",
  members: [
    {
      id: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
      label: "a",
      viewingHint: null,
      thumbnail: {
        iiifServiceUrl:
          "https://libimages1.princeton.edu/loris/figgy_prod/f7%2F67%2Ffe%2Ff767fe4247524c5f96e16eba2ff93301%2Fintermediate_file.jp2",
      },
      __typename: "FileSet",
    },
    {
      id: "8f0a0908-317f-414e-a78a-c38a4a3b28e3",
      label: "b",
      viewingHint: null,
      thumbnail: {},
      __typename: "FileSet",
    },
    {
      id: "ea01019e-f644-4416-b99c-1b44bf49d060",
      label: "c",
      viewingHint: null,
      thumbnail: {
        iiifServiceUrl:
          "https://libimages1.princeton.edu/loris/figgy_prod/d9%2Fb5%2F8c%2Fd9b58c8f3e554706bec4d977b12cd4e4%2Fintermediate_file.jp2",
      },
      __typename: "FileSet",
    },
  ],
}

const gallery = {
  state: {
    items: items,
    selected: [items[0]],
    cut: [],
    changeList: ["2"],
    ogItems: items,
  },
  mutations: galleryModule.mutations,
}

const actions = {
  loadImageCollectionGql: vi.fn()
}

let resource = {
  state: {
    resource: {
      id: "",
      resourceClassName: "",
      bibId: "",
      label: "Resource not available.",
      thumbnail: "",
      startCanvas: "",
      isMultiVolume: false,
      viewingHint: null,
      viewingDirection: null,
      members: [],
      loadState: "NOT_LOADED",
      saveState: "NOT_SAVED",
      ogState: {},
    },
  },
  mutations: resourceMutations,
  getters: resourceGetters,
  actions: actions,
}

let store = createStore({
  modules: {
    ordermanager: resource,
    gallery: gallery,
  },
})

describe("OrderManager.vue", () => {
  beforeEach(() => {

    wrapper = mount(OrderManager, {
      global: {
        plugins: [store],
        propsData: {
          resourceObject: resourceObject,
        },
        stubs: [
          "toolbar",
          "gallery",
          "text-style",
          "wrapper",
          "fileset-form",
          "controls",
          "lux-loader",
          "resource-form"],
      }
    })
  })

  it("has the right gallery items", () => {
    console.log('HTMLLLLLLLLLLLLLLLLLL')
    console.log(wrapper.vm.galleryItems)
    const items = wrapper.vm.galleryItems
    expect(items[0].caption).toBe("a")
    expect(items[0].mediaUrl).toBe(
      "https://libimages1.princeton.edu/loris/figgy_prod/f7%2F67%2Ffe%2Ff767fe4247524c5f96e16eba2ff93301%2Fintermediate_file.jp2/full/300,/0/default.jpg"
    )
    expect(items[1].mediaUrl).toBe("https://picsum.photos/600/300/?random")
  })

  it("has the right selectedTotal", () => {
    expect(wrapper.vm.selectedTotal).toBe(1)
  })

  it("returns whether or not the resource isMultiVolume", () => {
    expect(wrapper.vm.isMultiVolume).toBe(false)
  })

  it("returns whether or not the resource is Loading", () => {
    expect(wrapper.vm.loading).toBe(false)
  })

  it("returns whether or not the resource is Saved", () => {
    expect(wrapper.vm.saved).toBe(false)
  })

  it("returns whether or not the resource has a saveError", () => {
    expect(wrapper.vm.saveError).toBe(false)
  })

  it("resizes cards properly", () => {
    expect(wrapper.vm.cardPixelWidth).toBe(300)
    expect(wrapper.vm.captionPixelPadding).toBe(9)
    wrapper.vm.resizeCards({ target: { value: 70 } })
    expect(wrapper.vm.cardPixelWidth).toBe(70)
    expect(wrapper.vm.captionPixelPadding).toBe(0)
    wrapper.vm.resizeCards({ target: { value: 100 } })
    expect(wrapper.vm.captionPixelPadding).toBe(9)
  })

  it("calls the right action when no resourceObject is passed in", () => {
    // need to remount since the action only fires before mounting
    const wrapper2 = mount(OrderManager, {
      global: {
        plugins: [store],
        propsData: {
          resourceId: "foo",
        },
        stubs: ["toolbar", "gallery", "text-style", "wrapper", "fileset-form", "controls", "lux-loader", "resource-form"],
      }
    })
    expect(actions.loadImageCollectionGql).toHaveBeenCalled()
  })

  it("has the expected html structure", () => {
    expect(wrapper.element).toMatchSnapshot()
  })

  it("renders the links thumbnail", () => {
    expect(wrapper.vm.galleryItems.length).toEqual(3)
    expect(wrapper.vm.galleryItems[0]['mediaUrl']).toEqual('https://libimages1.princeton.edu/loris/figgy_prod/f7%2F67%2Ffe%2Ff767fe4247524c5f96e16eba2ff93301%2Fintermediate_file.jp2/full/300,/0/default.jpg')
  })

  describe('when the resources do not have IIIF service URLs', () => {

    let resourceObject = {
      id: "example2-id",
      label: "Resource with 1 files",
      viewingHint: "individuals",
      viewingDirection: "LEFTTORIGHT",
      startPage: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
      thumbnail: null,
      __typename: "ScannedResource",
      members: [
        {
      	  id: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
      	  label: "a",
      	  viewingHint: null,
      	  thumbnail: null,
      	  __typename: "FileSet",
      	}
      ],
      loadState: "LOADED",
      saveState: "NOT_SAVED",
      ogState: {}
    }

    resource = {
      state: {
        resource: resourceObject
      },
      mutations: resourceMutations,
      getters: resourceGetters,
      actions: actions,
    }

    let store = createStore({
      modules: {
        ordermanager: resource,
	      gallery: gallery,
      }
    })

    let wrapper = mount(OrderManager, {
      global: {
        plugins: [store],
        props: {
          resourceObject: resourceObject,
  	      defaultThumbnail: Global.figgy.resource.defaultThumbnail
        },
        stubs: ["toolbar", "gallery", "lux-text-style", "lux-wrapper", "fileset-form", "controls", "lux-loader", "resource-form"],
      }
    })

    it("renders the default Figgy thumbnail", () => {
      expect(wrapper.vm.defaultThumbnail).toEqual(Global.figgy.resource.defaultThumbnail)
      expect(wrapper.vm.galleryItems.length).toEqual(1)
      expect(wrapper.vm.galleryItems[0]['mediaUrl']).toEqual("https://institution.edu/repository/assets/random.png")
    })

    it("does not display an alert with an error message when the state is NOT SAVED", () => {
      expect(wrapper.text()).not.toContain('Sorry, there was a problem saving your work!')
    })
  })

  describe('when the resources errors on Save', () => {

    let resourceObject = {
      id: "example3-id",
      label: "Resource with 1 files",
      viewingHint: "individuals",
      viewingDirection: "LEFTTORIGHT",
      startPage: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
      thumbnail: null,
      __typename: "ScannedResource",
      members: [
        {
      	  id: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
      	  label: "a",
      	  viewingHint: null,
      	  thumbnail: null,
      	  __typename: "FileSet",
      	}
      ],
      loadState: "LOADED",
      saveState: "ERROR",
      ogState: {}
    }

    resource = {
      state: {
        resource: resourceObject
      },
      mutations: resourceMutations,
      getters: resourceGetters,
      actions: actions,
    }

    let store = createStore({
      modules: {
        ordermanager: resource,
	      gallery: gallery,
      }
    })

    let wrapper = mount(OrderManager, {
      global: {
        plugins: [store],
        propsData: {
          resourceObject: resourceObject,
  	      defaultThumbnail: Global.figgy.resource.defaultThumbnail
        },
        stubs: ["toolbar", "gallery", "text-style", "wrapper", "fileset-form", "controls", "loader", "resource-form"],
      }
    })

    it("displays an alert with an error message", () => {
      expect(wrapper.text()).toContain('Sorry, there was a problem saving your work!')
    })
  })
})
