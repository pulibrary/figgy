# Figgy Use Cases

## Multiple representations of the same resource
A resource may have more than one digitized representation. One known use case is where we have digitized and made publicly available the table of contents for an item, and added that to the catalog record as a link to the PDF. Then later a patron requests the item and we digitize it in full to make it available via the Virtual Reading Room / OARSC. The fully-digitized resource needs to be linked to the same catalog record as the excerpt, but needs its own ARK identifier

## Bound-withs / Sammelbands
Several separately-published works may have been bound together into a single volume. This isn't the same as a multi-volume-work because there is a cover and other pages that are unique to the item, and not part of any published work.

Currently Figgy does not handle this use case, and they are ingested as if they were simply a single-codex. They are added to the bib record for whichever item was requested by the patron. This makes it difficult for the patron to find the work they want to use.

## Maps
Scanned Maps usually only have one file set because a raster or vector is conceptualized as its own resource, usually created manually. This is different from books, where every page is one file set underneath a parent work.

A book will have 500 FileSets, a group of maps will be a MapSet with 500 ScannedMaps as member resources.

## Mosaic data sets

We need to provide mosaic tile services for two categories of map sets. for more
info see [/docs/mosaic.md](/docs/mosaic.md)

### Scanned maps with associated rasters
Example: A set of maps that have been scanned and then processed into georeferenced tiffs

The scanned map and the georeferenced tiff need to stay affiliated with one another.

### Raster sets
Example: Aerial Imagery

## Multispectral Images

Projects where each sheet is imaged multiple times under different lighting
conditions, wavelengths, and focuses. Also known as "Moveable Metal Type
Multispectral Imaging."

We receive these files from a vendor in the following structure (arrow brackets
indicate values to be filled in, square brackets represent optional values)

- 📁 Princeton
  - 📁 \<MMSID\>
    - 📁 f\<sheet number\>\<r/v\>\[x/y/z\] (r/v stands for recto/verso) (x/y/z
    indicate another set of shots for a page - e.g for a closer shot)
      - 💿 Princeton_\<MMSID\>\_f\<sheet
      number\>\<r/v\>\[x/y/z\]\_###\<N/R/G\>\_\<shot_number\>\_\<R/F\>.tif
      (### is wavelength, N/R/G represent filter - none, red, or green)
      - 💿 Princeton_\<MMSID\>\_f\<sheet number\>\<r/v\>\[x/y/z\].json (JSON
        file describing all the images' technical metadata.)
        (This file will be stored but not parsed - all the technical metadata is
        duplicated either in the filename or the EXIF metadata of the image.)

For more on the meaning of the filename see the contractor's
[README](https://docs.google.com/document/d/1rjVgnUizdSrR1EsxaTV5RyHIOEWyUze8kjyS9ICPkyM/edit?usp=sharing)

These resources are ingested via bulk ingest or "Save and Ingest" and results in
a multi-volume work resource with one volume per "page" and 25 images per side
of page. If the resource is already digitized then the catalog will have two
viewers - one for the multispectral images and one for the resource as a whole.
The filename at ingest must be preserved in perpetuity, even if the label
changes in the future, as it acts as technical metadata.

When viewers support
["non-paged"](https://preview.iiif.io/cookbook/3333-choice/recipe/0035-foldouts/) IIIF hints or
["choice"](https://preview.iiif.io/cookbook/3333-choice/recipe/0033-choice/) such that we can interleave normal
page scans with multispectral scans we hope to combine these resources for a
better experience.

## Illiad PDF OCR

The resource sharing department enhances PDF scans with OCR while fulfilling
patron requests. We do this in Figgy because Figgy does other OCR stuff.

The way this works:

1. Resource sharing department puts a PDF at `/mnt/illiad/ocr_scans` (or the
   equivalent on their machine)
1. Figgy has a [FileWatcher](/bin/pdf_watcher) that runs on
   lib-proc9.princeton.edu and looks for new files on that mount. When a new
   file is seen, it enqueues a CreateOcrRequestJob.
   * We use a file watcher instead of a cron job so that it runs immediately.
   * lib-proc9 is chosen here:
   https://github.com/pulibrary/princeton_ansible/blob/d5bb4fc6bb44047502062cb65e154b443136cfa8/playbooks/figgy_production.yml#L65
