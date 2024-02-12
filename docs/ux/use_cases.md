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

## Supplemental content PDFs
Recordings of local concerts have associated scanned concert programs. Users
prefer a link to a pdf to display in the record, rather than modeling the items
so that they both appear in a viewer. The recording and PDF are ingested
separately, and a link to the PDF is entered into the catalog record 856 field
as `https://arks.princeton.edu/<arkhere>/pdf`. This means that our system needs
to support that route moving forward, or we would lose access to these pdfs.


## Bulk Ingest ETDs from RDSS

Every year RDSS bulk ingests senior theses and dissertations into Figgy, with
per-resource visibility and embargoes set. Every thesis has a record in Alma
identified by an MMS ID.

RDSS sets up a directory structure that looks like this on the isilon:

* 📁 theses_ingest_2022
    * 📁 \<mmsid\>
        * 💿 figgy_metadata.json
        * 💿 \<filename\>.pdf
    * 📁 \<mmsid\>
        * 💿 figgy_metadata.json
        * 💿 \<filename\>.pdf

### figgy_metadata.json

The JSON file has a structure that looks like this:

```json
{
  "embargo_date": "01/21/2023",
  "visibility": "open",
  "notice_type": "senior_thesis"
}
```
`embargo_date` is in the format `mm/dd/yyyy`, and is optional

`visibility` is either:

* `open`: Viewable and downloadable by all users.
* `princeton`: Viewable by users with Princeton NetIDs
* `on campus`: Viewable by users on VPN or on Campus.
* `reading room`: Viewable by users in the reading room or via Virtual Reading
Room.
* `private`: Not viewable by anyone (except library staff with Figgy staff/admin access)

`notice_type` being set to "senior_thesis" makes the senior thesis click-through
in the viewer happen.

### Ingest

After setting up the structure, RDSS uses the "Bulk Ingest Scanned Resources"
interface in Figgy to select `thesis_ingest_2022`, select a collection to put
them into if appropriate, and then submits. The visibility chosen in the
interface will be the default for any resource which doesn't have visibility set
in `figgy_metadata.json`.


## CollectorSystems

PUL Preservation & Conservation uses
[CollectorSystems](https://www.collectorsystems.com/index.htm) to manage their
workflows. They've worked with a developer there to add custom import processes
into CollectorSystems. APIs it requires are:

1. Fetch all Figgy objects linked to a source metadata identifier which are
   restricted
   * https://figgy.princeton.edu/catalog?q=source_metadata_identifier_ssim:9934953393506421&format=json&f[visibility_ssim][]=restricted
   * An `auth_token=` parameter is appended to this to make it work. They've
   been provided an auth token which is in Figgy as "Collector Systems"
1. Get a Manifest from a Figgy ID
   * https://figgy.princeton.edu/concern/scanned_resources/8fda0322-a636-47ca-8fc8-b297605ef9c3/manifest
   * An `auth_token=` parameter is appended to this to make it work. They've
   been provided an auth token which is in Figgy as "Collector Systems"
1. Provide the "Original Filename" of each FileSet in the IIIF Manifest.
   * Preservation & Conservation stores information in that filename.
   * Not implemented yet - see #5286

CollectorSystems also integrates with Pulfalight & Bibdata to pull metadata.

1. Bibdata: https://bibdata.princeton.edu/bibliographic/<id>.xml
2. Finding Aids: https://findingaids.princeton.edu/<id>.jsonld

## Original/PreservationFile/IntermediateFile

When going through Figgy you'll find three types of file Uses that are
associated with a "primary file" - Original, PreservationFile, and
IntermediateFile.

OriginalFile expands to the URI http://pcdm.org/use#OriginalFile

PreservationFile expands to the URI http://pcdm.org/use#PreservationFile

IntermediateFile expands to the URI http://pcdm.org/use#IntermediateFile

### Original Files

When a FileSet has only one file from which derivatives should be created by the
system, then it is an original file.

### PreservationFile / IntermediateFile

Sometimes there's two files that are important to preserve - the source file and
a hand-crafted derivative of that file, which can't be automatically recreated.
Derivatives should be created from that hand-crafted file, but the source file
should be preserved and downloadable by staff. Both the
PreservationFile/IntermediateFile should be preserved, as they can't be created
from one another programmatically. Some examples of this use case
are below:

#### Watermarks

We have a couple instances in Figgy where there's a file without a watermark,
and then a modification of that file with a watermark hand-placed via image
editing software. Derivatives should include the watermark because we have to
distribute the watermark, but it's important to preserve the original photo.

The file without the watermark is ingested as a PreservationFile, and the one
with is ingested as an IntermediateFile. Derivatives are generated from the
IntermediateFile. FileSet#primary_file returns the PreservationFile, and both
are preserved.

#### Audio Files

We have some content which has been returned to us from vendors in a bag format
and includes a gigantic audio file, and a hand-crafted slightly compressed
version of that file from which access copies can be created. We want the large
file, but don't need to create derivatives from it.

So, the gigantic file is ingested as a PreservationFile, and the compressed file
is ingested as an IntermediateFile. FileSet#primary_file returns the
PreservationFile, and both are preserved.

## Videos

We have the following use cases for video:

As Princeton University I should only allow the public to view videos that have subtitles which can render in the viewer both to legally protect ourselves and more importantly to meet our goals of accessibility. We want (.VTT) files for transcription subtitles so that we can standardize and migrate if need be.

As a Figgy staff member I should be able to bulk ingest several videos, each with their own resource along with their captions so that I can have a vendor mass digitize materials and then ingest them later.

As a Figgy staff member I should be able to ingest several videos to one resource, each with their own captions, and the viewer should render them with a table of contents so that I can display multiple videos in a single "box" of content in the archives.

As Princeton University I want to preserve the captions along with the video so that if Figgy's data is ever lost I can restore them.

As a researcher I want to have multiple captions each in their own language and users should be able to switch between them so that I can provide translations in addition to transcription. The default caption should be the first one uploaded.
