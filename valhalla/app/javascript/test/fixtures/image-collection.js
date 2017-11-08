export const imageCollection = [
  {
    "label":"baz",
    "id":"50b5e49b-ade7-4278-8265-4f72081f26a5",
    "page_type":"single",
    "url":"http://example.com"
  },
  {
    "label":"foo",
    "id":"dae7619f-16a7-4306-93e4-70b4b192955c",
    "page_type":"single",
    "url":"http://example.com"
  }]

export const emptyChangeList = []
export const changeList = ['50b5e49b-ade7-4278-8265-4f72081f26a5']

export const selected = [
  {
    "label":"baz",
    "id":"50b5e49b-ade7-4278-8265-4f72081f26a5",
    "page_type":"single",
    "url":"http://example.com"
  }]

export const sortedImages = [
  {
    "label":"foo",
    "id":"dae7619f-16a7-4306-93e4-70b4b192955c",
    "page_type":"single",
    "url":"http://example.com"
  },
  {
    "label":"baz",
    "id":"50b5e49b-ade7-4278-8265-4f72081f26a5",
    "page_type":"single",
    "url":"http://example.com"
  }
]

export const multipleSelected = [
  {
    "label":"baz",
    "id":"50b5e49b-ade7-4278-8265-4f72081f26a5",
    "page_type":"single",
    "url":"http://example.com"
  },
  {
    "label":"p. foo",
    "id":"dae7619f-16a7-4306-93e4-70b4b192955c",
    "page_type":"single",
    "url":"http://example.com"
  }]

export const thumbnail = "50b5e49b-ade7-4278-8265-4f72081f26a5"
export const startPage = "50b5e49b-ade7-4278-8265-4f72081f26a5"

export const initState = {
  "id": "9a25e0ce-4f64-4995-bae5-29140a453fa3",
  "resourceClassName": "ephemera_folder",
  "startpage": "",
  "thumbnail": "80b02791-4bd9-4566-9a9f-4b3062ba2e0d",
  "viewingDirection": "left-to-right",
  "viewingHint": "individuals",
  "changeList" : [],
  "images": [
    {
      "label": "[p. i (recto)]",
      "id": "e7208ea3-21f3-43d4-9b14-489e15e9791e",
      "page_type": "single",
      "url": "\/packs\/_\/_\/_\/app\/assets\/images\/default-1927ff44629d419a4bb2dfdc4317a78a.png"
    },
    {
      "label": "[p. i (verso)]",
      "id": "50b5e49b-ade7-4278-8265-4f72081f26a5",
      "page_type": "single",
      "url": "http:\/\/localhost:3000\/image-service\/50b5e49b-ade7-4278-8265-4f72081f26a5\/full\/400,\/0\/default.jpg"
    },
    {
      "label": "[p. ii (recto)]",
      "id": "dae7619f-16a7-4306-93e4-70b4b192955c",
      "page_type": "single",
      "url": "http:\/\/localhost:3000\/image-service\/dae7619f-16a7-4306-93e4-70b4b192955c\/full\/400,\/0\/default.jpg"
    },
    {
      "label": "[p. ii (verso)]",
      "id": "b484cd88-fdf2-477c-afe9-d46a49d8822b",
      "page_type": "single",
      "url": "http:\/\/localhost:3000\/image-service\/b484cd88-fdf2-477c-afe9-d46a49d8822b\/full\/400,\/0\/default.jpg"
    },
    {
      "label": "foo",
      "id": "80b02791-4bd9-4566-9a9f-4b3062ba2e0d",
      "page_type": "single",
      "url": "http:\/\/localhost:3000\/image-service\/80b02791-4bd9-4566-9a9f-4b3062ba2e0d\/full\/400,\/0\/default.jpg"
    },
    {
      "label": "[p. iii (verso)]",
      "id": "0a3e268f-5872-444e-bdbd-b1a7b01dcb57",
      "page_type": "single",
      "url": "\/packs\/_\/_\/_\/app\/assets\/images\/default-1927ff44629d419a4bb2dfdc4317a78a.png"
    }
  ]
}

export const body = {
  "resource": {
    "ephemera_folder": {
      "member_ids": [
        "50b5e49b-ade7-4278-8265-4f72081f26a5",
        "0a3e268f-5872-444e-bdbd-b1a7b01dcb57",
        "e7208ea3-21f3-43d4-9b14-489e15e9791e",
        "dae7619f-16a7-4306-93e4-70b4b192955c",
        "b484cd88-fdf2-477c-afe9-d46a49d8822b",
        "80b02791-4bd9-4566-9a9f-4b3062ba2e0d"
      ],
      "thumbnail_id": "80b02791-4bd9-4566-9a9f-4b3062ba2e0d",
      "start_canvas": "",
      "viewing_hint": "individuals",
      "viewing_direction": "right-to-left",
      "id": "9a25e0ce-4f64-4995-bae5-29140a453fa3"
    }
  },
  "file_sets": [
    {
      "id": "50b5e49b-ade7-4278-8265-4f72081f26a5",
      "title": "p. i",
      "page_type": "single"
    },
    {
      "id": "0a3e268f-5872-444e-bdbd-b1a7b01dcb57",
      "title": "p. ii",
      "page_type": "single"
    },
    {
      "id": "e7208ea3-21f3-43d4-9b14-489e15e9791e",
      "title": "p. iii",
      "page_type": "single"
    },
    {
      "id": "dae7619f-16a7-4306-93e4-70b4b192955c",
      "title": "p. iv",
      "page_type": "single"
    },
    {
      "id": "b484cd88-fdf2-477c-afe9-d46a49d8822b",
      "title": "p. v",
      "page_type": "single"
    },
    {
      "id": "80b02791-4bd9-4566-9a9f-4b3062ba2e0d",
      "title": "p. vi",
      "page_type": "single"
    }
  ]
}

const fixtures = {
  imageCollection,
  emptyChangeList,
  changeList,
  selected,
  multipleSelected,
  sortedImages,
  thumbnail,
  startPage,
  initState,
  body
}

export default fixtures
