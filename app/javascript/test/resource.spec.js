import Vuex from "vuex"
import storeConfig from "../helpers/resource-store-config.js"
import { cloneDeep } from "lodash"

const resourceObject = {
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
      thumbnail: {
        iiifServiceUrl:
          "https://libimages1.princeton.edu/loris/figgy_prod/a5%2F15%2F62%2Fa515627580594c978ce5352653c9442a%2Fintermediate_file.jp2",
      },
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

const reordered = [
  {
    id: "bar",
    title: "example.tif",
    caption: "FileSet : 8f0a0908-317f-414e-a78a-c38a4a3b28e3",
    mediaUrl: "https://picsum.photos/600/300/?random",
  },
  {
    id: "foo",
    title: "example.tif",
    caption: "FileSet : 8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
    mediaUrl: "https://picsum.photos/600/300/?random",
  },
  {
    id: "baz",
    title: "example.tif",
    caption: "FileSet : ea01019e-f644-4416-b99c-1b44bf49d060",
    mediaUrl: "https://picsum.photos/600/300/?random",
  },
]

it("updates state when CHANGE_RESOURCE_LOAD_STATE is commited", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  expect(store.state.resource.loadState).toBe("NOT_LOADED")
  store.commit("CHANGE_RESOURCE_LOAD_STATE", "LOADED")
  expect(store.state.resource.loadState).toBe("LOADED")
})

it("updates state when SAVED_STATE is commited", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  expect(store.state.resource.saveState).toBe("NOT_SAVED")
  store.commit("SAVED_STATE", "SAVED")
  expect(store.state.resource.saveState).toBe("SAVED")
})

it("updates state appropriately when SET_RESOURCE is commited", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  expect(store.state.resource.startCanvas).toBe("")
  expect(store.state.resource.members.length).toBe(0)
  store.commit("SET_RESOURCE", resourceObject)
  expect(store.state.resource.startCanvas).toBe("8ffd7a03-ec0e-46c1-a347-e4b19cb7839f")
  expect(store.state.resource.viewingHint).toBe("individuals")
  expect(store.state.resource.viewingDirection).toBe("LEFTTORIGHT")
  expect(store.state.resource.resourceClassName).toBe("ScannedResource")
  expect(store.state.resource.thumbnail).toBe("8ffd7a03-ec0e-46c1-a347-e4b19cb7839f")
  expect(store.state.resource.members.length).toBe(3)
})

it("updates start canvas when UPDATE_STARTCANVAS is commited", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  expect(store.state.resource.startCanvas).toBe("")
  store.commit("UPDATE_STARTCANVAS", "foo")
  expect(store.state.resource.startCanvas).toBe("foo")
})

it("updates thumbnail when UPDATE_THUMBNAIL is committed", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  store.commit("SET_RESOURCE", resourceObject)
  expect(store.state.resource.thumbnail).toBe("8ffd7a03-ec0e-46c1-a347-e4b19cb7839f")
  expect(store.getters.stateChanged).toBe(false)
  store.commit("UPDATE_THUMBNAIL", "bar")
  expect(store.state.resource.thumbnail).toBe("bar")
  expect(store.getters.stateChanged).toBe(true)
})

it("nullifies the thumbnail when UPDATE_THUMBNAIL is committed without an ID", () => {
    const store = new Vuex.Store(cloneDeep(storeConfig))
    store.commit("SET_RESOURCE", resourceObject)
    expect(store.state.resource.thumbnail).toBe("8ffd7a03-ec0e-46c1-a347-e4b19cb7839f")
    expect(store.getters.stateChanged).toBe(false)
    store.commit("UPDATE_THUMBNAIL", null)
    expect(store.state.resource.thumbnail).toBe(null)
    expect(store.getters.stateChanged).toBe(true)
})


it("updates viewing direction when UPDATE_VIEWDIR is commited", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  expect(store.state.resource.viewingDirection).toBe(null)
  store.commit("UPDATE_VIEWDIR", "foo")
  expect(store.state.resource.viewingDirection).toBe("foo")
})

it("updates viewing direction when UPDATE_VIEWHINT is commited", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  expect(store.state.resource.viewingHint).toBe(null)
  store.commit("UPDATE_VIEWHINT", "baz")
  expect(store.state.resource.viewingHint).toBe("baz")
})

// getters
it("gets the right member count from getMemberCount", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  expect(store.getters.getMemberCount).toBe(0)
  store.commit("SET_RESOURCE", resourceObject)
  expect(store.getters.getMemberCount).toBe(3)
})

it("returns whether or not the resource has multiple volumes from isMultiVolume", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  store.commit("SET_RESOURCE", resourceObject)
  expect(store.getters.isMultiVolume).toBe(false)
})

it("should return true if item order changes from orderChanged", () => {
  const store = new Vuex.Store(cloneDeep(storeConfig))
  store.commit("SET_RESOURCE", resourceObject)
  expect(store.state.gallery.items[0].id).toBe("8ffd7a03-ec0e-46c1-a347-e4b19cb7839f")
  expect(store.getters.orderChanged).toBe(false)
  expect(store.getters.stateChanged).toBe(false)
  store.commit("SORT_ITEMS", reordered)
  expect(store.state.gallery.items[0].id).toBe("bar")
  expect(store.getters.orderChanged).toBe(true)
  expect(store.getters.stateChanged).toBe(true)
})
