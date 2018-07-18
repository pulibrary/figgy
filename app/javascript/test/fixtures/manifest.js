export const manifest = {
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@type": "sc:Manifest",
  "@id": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest",
  "label": [
    "Resource with 3 files"
  ],
  "description": "Plant a memory, plant a tree, do it today for tomorrow.",
  "viewingHint": "paged",
  "viewingDirection": "left-to-right",
  "metadata": [
    {
      "label": "Created At",
      "value": [
        "07/09/18 05:20:06 PM UTC"
      ]
    },
    {
      "label": "Updated At",
      "value": [
        "07/17/18 02:34:06 PM UTC"
      ]
    },
    {
      "label": "Identifier",
      "value": [
        "ark:/99999/fk4wq16k1g"
      ]
    },
    {
      "label": "Title",
      "value": [
        "Resource with 3 files"
      ]
    },
    {
      "label": "Description",
      "value": [
        "Plant a memory, plant a tree, do it today for tomorrow."
      ]
    },
    {
      "label": "PDF Type",
      "value": [
        "gray"
      ]
    },
    {
      "label": "Source Metadata Identifier",
      "value": [
        "4609321"
      ]
    },
  ],
  "sequences": [
    {
      "@type": "sc:Sequence",
      "@id": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/sequence/normal",
      "rendering": [
        {
          "@id": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/pdf",
          "label": "Download as PDF",
          "format": "application/pdf"
        }
      ],
      "canvases": [
        {
          "@type": "sc:Canvas",
          "@id": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/canvas/291b467b-36af-4d1e-80f1-dc76e8e250b9",
          "label": "example.tif",
          "rendering": [
            {
              "@id": "http://localhost:3000/downloads/291b467b-36af-4d1e-80f1-dc76e8e250b9/file/03c0e5bf-6a45-46a8-84c4-c82116be7d1b",
              "label": "Download the original file",
              "format": "image/tiff"
            }
          ],
          "width": 200,
          "height": 287,
          "images": [
            {
              "@type": "oa:Annotation",
              "motivation": "sc:painting",
              "resource": {
                "@type": "dctypes:Image",
                "@id": "http://localhost:3000/image-service/291b467b-36af-4d1e-80f1-dc76e8e250b9/full/!1000,/0/default.jpg",
                "height": 287,
                "width": 200,
                "format": "image/jpeg",
                "service": {
                  "@context": "http://iiif.io/api/image/2/context.json",
                  "@id": "http://localhost:3000/image-service/291b467b-36af-4d1e-80f1-dc76e8e250b9",
                  "profile": "http://iiif.io/api/image/2/level2.json"
                }
              },
              "on": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/canvas/291b467b-36af-4d1e-80f1-dc76e8e250b9"
            }
          ]
        },
        {
          "@type": "sc:Canvas",
          "@id": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/canvas/acb1c188-57c4-41cb-88e0-f44aca12e565",
          "label": "example.tif",
          "rendering": [
            {
              "@id": "http://localhost:3000/downloads/acb1c188-57c4-41cb-88e0-f44aca12e565/file/eb3d4f51-13c2-4ae6-9c20-41cb02ecb169",
              "label": "Download the original file",
              "format": "image/tiff"
            }
          ],
          "width": 200,
          "height": 287,
          "images": [
            {
              "@type": "oa:Annotation",
              "motivation": "sc:painting",
              "resource": {
                "@type": "dctypes:Image",
                "@id": "http://localhost:3000/image-service/acb1c188-57c4-41cb-88e0-f44aca12e565/full/!1000,/0/default.jpg",
                "height": 287,
                "width": 200,
                "format": "image/jpeg",
                "service": {
                  "@context": "http://iiif.io/api/image/2/context.json",
                  "@id": "http://localhost:3000/image-service/acb1c188-57c4-41cb-88e0-f44aca12e565",
                  "profile": "http://iiif.io/api/image/2/level2.json"
                }
              },
              "on": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/canvas/acb1c188-57c4-41cb-88e0-f44aca12e565"
            }
          ]
        },
        {
          "@type": "sc:Canvas",
          "@id": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/canvas/c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab",
          "rendering": [
            {
              "@id": "http://localhost:3000/downloads/c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab/file/49dbdca5-5c9e-450b-a67b-dfa97cd85e52",
              "label": "Download the original file",
              "format": "image/tiff"
            }
          ],
          "width": 200,
          "height": 287,
          "images": [
            {
              "@type": "oa:Annotation",
              "motivation": "sc:painting",
              "resource": {
                "@type": "dctypes:Image",
                "@id": "http://localhost:3000/image-service/c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab/full/!1000,/0/default.jpg",
                "height": 287,
                "width": 200,
                "format": "image/jpeg",
                "service": {
                  "@context": "http://iiif.io/api/image/2/context.json",
                  "@id": "http://localhost:3000/image-service/c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab",
                  "profile": "http://iiif.io/api/image/2/level2.json"
                }
              },
              "on": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/canvas/c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab"
            }
          ]
        }
      ],
      "viewingHint": "paged",
      "startCanvas": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/canvas/291b467b-36af-4d1e-80f1-dc76e8e250b9"
    }
  ],
  "structures": [
    {
      "@type": "sc:Range",
      "@id": "http://localhost:3000/concern/scanned_resources/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d/manifest/range/r704aaa5a-dc37-473b-a4c6-234bc28ea46d",
      "label": "Logical",
      "viewingHint": "top",
      "ranges": [

      ],
      "canvases": [

      ]
    }
  ],
  "seeAlso": {
    "@id": "http://localhost:3000/catalog/4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d.jsonld",
    "format": "application/ld+json"
  },
  "license": "http://rightsstatements.org/vocab/InC-NC/1.0/",
  "rendering": {
    "@id": "http://arks.princeton.edu/ark:/99999/fk4wq16k1g",
    "format": "text/html"
  },
  "logo": "http://localhost:3000/assets/pul_logo_icon-7b5f9384dfa5ca04f4851c6ee9e44e2d6953e55f893472a3e205e1591d3b2ca6.png",
  "thumbnail": {
    "@id": "http://localhost:3000/image-service/80b02791-4bd9-4566-9a9f-4b3062ba2e0d/full/!200,150/0/default.jpg",
    "service": {
      "@context": "http://iiiif.io/api/image/2/context.json",
      "@id": "http://localhost:3000/image-service/80b02791-4bd9-4566-9a9f-4b3062ba2e0d",
      "profile": "http;//iiiif.io/api/image/2/level2.json"
    }
  }
}

export default manifest
