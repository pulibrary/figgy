# Collection Discovery

Collections in Figgy vary in scope, from archival collections, to the set of items selected for an
exhibition, to a group created by staff for workflow purposes. To identify a collection of interest,
consult the manifest of all Figgy collections at:

    https://figgy.princeton.edu/iiif/collections/

This manifest includes an entry for each Figgy collection, including a label, and the collection
manifest URL. In the `collections` array, each collection will have an entry that looks like this:

```json
{
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@type": "sc:Collection",
  "@id": "https://figgy.princeton.edu/collections/52abe8f7-e2a1-46e9-9d13-3dc4fbc0bf0a/manifest",
  "label": [
    "Princeton Digital Library of Islamic Manuscripts"
  ],
  "description": [
    "As a result of generous support from the David A. Gardner '69 Magic Project, the Princeton..."
  ],
  "metadata": [
    {
      "label": "Exhibit",
      "value": [
        "islamicmss"
      ]
    }
  ],
  "seeAlso": {
    "@id": "https://figgy.princeton.edu/catalog/52abe8f7-e2a1-46e9-9d13-3dc4fbc0bf0a.jsonld",
    "format": "application/ld+json"
  }
}
```

The `@id` property contains the URI to retrieve the collection manifest, and `seeAlso` includes metadata
about the collection. Depending on the kind of collection, it might have very minimal metadata in JSON
format, and their might be rich metadata in EAD XML format.

# Item Discovery

Each collection manifest includes an entry for each item in the collection, including a label,
thumbnail, and the item manifest URL. The `manifests` array will include an entry for each item that
looks like this:

```json
{
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@type": "sc:Manifest",
  "@id": "https://figgy.princeton.edu/concern/scanned_resources/3c608517-145c-4270-965f-f44a86c0457c/manifest",
  "label": [
    "حسن الدعوة للاجابة الى القهوة / جمع عبد الله الادكاوي.",
    "Ḥusn al-daʻwah lil-ijābah ilá al-qahwah / jamʻ ʻAbd Allāh al-Udkāwī."
  ],
  "description": [
    "Ms. codex.",
    "Title from title page (fol. 1a).",
    "A few marginal notes. Title page note that it is copied from a text in the author's hand. Folio...",
    "Collation: Paper ; fol. i + 11 ; catchwords ; modern foliation in pencil using Western numerals.",
    "Layout: 19 lines per page in two columns.",
    "Description: Rubricated ; watermarks (shield with three stars) ; MS in good condition.",
    "Origin: According to colophon copy completed 8 Dhū al-Qaʻdah 1283 by Muḥammad ibn Ḥasanayn (fol. 10a).",
    "Incipit: بسم الله الرحمن الرحيم وبه ثقتى الحمد لله رب العالمين ... وبعد فهذه نبذة انتقيتها من قطعة جمعها بعض الافاضل فيما يتعلق بالقهوة البنيه المجلوبة الى الاقطار من البلاد اليمنية ...",
    "Colophon: نجزت کتابته في ثمان خلت من ذي القعدة الحرام سنة ثلاث وثمانين ومائتين والف. کتبه الفقير لرحمة ربه محمد حسنين"
  ]
}
```

# Item Information

Each item manifest contains metadata (both a `metadata` hash, and JSON-LD and typically either EAD
or MARC XML in `seeAlso`), images or other media, a thumbnail, and a license statement.  Most
objects also include links to download each page image, and to download the entire object as a PDF.

## Metadata

Basic information about the item is provided in the `label` and `description` properties. Extended info
is included in the `metadata` hash, `license` property, and in the metadata linked to in `seeAlso`.
Additional properties include information about how to display the item, such as `viewingHint`,
`viewingDirection`, and `thumbnail`.

## Content

The main content of the object is included in `sequences`. The `rendering` object will include the URI
to access a PDF version of the object (if available), and the `canvases` array will include information
about each page. Each canvas will include a label, and a IIIF image service for the main content. The
`rendering` object will include the URI to download the image and/or page text (if available).

## Structure

Some items have an encoded table of contents in the `structures` object.
