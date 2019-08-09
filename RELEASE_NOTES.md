<!--

Release notes template:

# 2019-08-07

## Added

## Fixed

## Changed

## Removed

-->
# 2019-08-09

## Fixed

* Archival media collection upload will accept images with all-caps `JPG`
  extension
* Removed dead space at the top of the viewer.

# 2019-08-08

## Changed

* Visibility badge notices have been updated to reflect new authentication
  feature in the viewer

# 2019-08-07

## Added

* Updating the UniversalViewer to support A/V resources with fully expanded displays of attached image content

## Fixed

* Clear derivative generation error message from file set when that file set's derivatives are cleaned up

## Changed

* Links in the cover pages for generated PDFs direct users to public-facing platforms (DPUL, the catalog, or the finding aids)

# 2019-08-06

## Added

* If in a configured IP, reading room users can now log in to view Reading Room Only material.
* Added ability to ingest ephemera with MODS metadata.

## Fixed

* Users should now be prevented from submitting multiple Order Manager updates before the initial update has successfully updated the Resource

* The file upload interface should now filter hidden files on the file system within the File Manager for Resources
* Imported metadata attributes are now indexed without brackets, class names, etc.

# 2019-08-05

## Changed

* Music Reserves import now appends courses for existing recordings instead of simply
skipping them.

## Removed

* Removed redundant "Figgy" home link from secondary header

# 2019-08-02

## Fixed

* Email addresses for external users no longer have "@princeton.edu" added to the end of valid email addresses.

# 2019-07-26

## Added

* Added release notes. [#3225](https://github.com/pulibrary/figgy/issues/3217)
* Display Princeton Only resources in the Catalog if appropriate.
* Display title of a playlist at the top of the Playlist viewer. [#3203](https://github.com/pulibrary/figgy/issues/3203)
* Add depositor facet [#3217](https://github.com/pulibrary/figgy/issues/3217)

## Fixed

* Don't ingest hidden files which start with a `.`
[#3201](https://github.com/pulibrary/figgy/issues/3201)
[#3294](https://github.com/pulibrary/figgy/issues/3294)
* When adding tracks to a playlist don't display table headings until there are
  search results. [#3035](https://github.com/pulibrary/figgy/issues/3035)
* Fix music reserves being able to play after ingest.
