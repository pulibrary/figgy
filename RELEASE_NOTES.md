<!--

Release notes template:

# 2020-05-14

## Added

## Fixed

## Changed

## Removed

-->
# 2020-05-14

## Fixed

* Numismatics issue Shape field prepopulates the correct value

# 2020-05-08

## Changed

* File Manager is now ordered alphabetically.
* Hidden files are no longer displayed in file manager.

# 2020-04-30

## Added

* Add link to finding aid on show page when source metadata id is a component id.

# 2020-04-29

## Added

* Add support for bracketing of even and odd numbered pages in order manager.

# 2020-04-28

## Added

* Allow unnumbered labels in order manager.
* Added the ability to "claim" a resource to work on.

# 2020-04-27

## Fixed

* GeoBlacklight documents with incorrect imported coverage can now sync.

# 2020-04-24

## Removed

* Removed support for ingesting JPEG2000 files.

# 2020-04-23

## Fixed

* Added a loading bar to the order manager while it's saving.
* Disabled the "Apply Changes" button for order manager while saving.

# 2020-04-22

## Added

* Added two-up support to order manager.

## Fixed

* Removing a source metadata identifier now clears imported metadata.
*
# 2020-04-21

## Added

* Upgraded the file and Google Drive upload interface for resources and the bulk ingest interface

# 2020-04-16

## Added

* Added support for ingesting JPEG2000 files.

# 2020-04-10

## Fixed

* Allow Coin resource images to be downloaded from UV.

# 2020-04-09

## Fixed

* Fixed PDF generation for coin resources.

# 2020-04-03

## Added

* Added support for ingesting PNG files.

# 2020-03-30

## Changed

* Image files now generate a Pyramidal Tiff and upload it to AWS for a new image
server implementation.

# 2020-03-16

## Fixed

* PDFs now properly display in the viewer.

# 2020-03-12

## Changed

* JP2 derivatives are now generated via OpenJPEG instead of Kakadu.

# 2020-02-28

## Added

* Assign Coin FileSets a title based on image file name.

# 2020-02-28

## Changed

* Allow coin thumbnail to be set in the order manager.

# 2020-02-28

## Changed

* Refines indexed numismatic reference title.

# 2020-02-28

## Added

* Indexes a unique numismatic reference title into Solr.
* Drop-down menus for references will display this title.

# 2020-02-28

## Changed

* Sort numismatics drop down values alphabetically.

# 2020-02-28

## Changed

* Hide PDF Type field on Coin edit form.

# 2020-02-27

## Changed

* Removed the holding location property from numismatics coin.

# 2020-02-27

## Changed

* Reorganized nest citation form.
* Added a citation type field to citiations.

# 2020-02-27

## Added

* Update on the 'Numismatic Issue' form the label 'Numismatic Place' to 'Minting Location'.
* Move the 'Numismatic Place' field under the 'Ruler' field.  

# 2020-02-27

## Added

* Update layout/Move in one line Earliest Date and Latest Date fields.
* Update layout/Move in one line Era and Date of the Object fields.

# 2020-02-26

## Added

* Added firm and person ajax drop downs to numismatics accessions.
* Added buttons for new Numismatic Ruler and Master.

# 2020-02-26

## Changed

* Sort coins in members data table by date uploaded.

# 2020-02-24

## Changed

* Update the numismatics form to have smaller padding and margin.

# 2020-02-21

## Changed

* Allow Coins, Scanned Maps, Vector Resources, and Raster Resources to be bulk
  edited.

# 2020-02-21

## Fixed

* Fixed downloads of HLS content with a playlist auth token.

# 2020-02-18

## Changed

* Move the monograms to the bottom of the page. Keep the Monograms panel collapsed when the page loads.
* Remove Rights and Notes panel from the Numismatics issue and coin form
* Move the Save, Cancel buttons to the bottom of the form
* Remove Progress form sidebar from the Numismatics issue form.
* Add a button in the form to open a new tab to create New Person, New Place, New Firm

# 2020-02-20

## Changed

* Electronic locations are now imported from bib record 856 fields.

# 2020-02-19

## Added

 * Logs users out of CAS when logging out of Figgy

# 2020-02-18

## Changed

 * Allows for unicode characters in ajax search
 * Improves search and formatting in numismatics search components

# 2020-02-17

## Fixed

 * Fixed title and location for Coin documents ingested into Orangelight

# 2020-02-14

## Changed

 * Sets default state of Numismatics Issues to "complete".
 * Prevents propagation of Issue state to Coin members.
 * Stops minting ARKs for Issues.

# 2020-02-14

## Added

 * Integrated the "Save and Duplicate Metadata" feature for Numismatic Issues and
  Coins

## Fixed

 * Restored the dropdown form widget for the artist and citation fields

# 2020-02-13

## Added

* Adds additional numismatic resource dropdowns.

# 2020-02-13

## Changed

 * Ensured that the Universal Viewer is not rendered for Numismatic Issues when
   there are no attached Coins, or, when attached Coins do not have files
   uploaded for them.
* Updating the attributes "Ce1" and "Ce2" labels to "Earliest Date" and "Latest
  Date" for Numismatic Issues; Updating the attributes "Weight" and "Size" to
  "Weight (g)" and "Size (mm)" for Numismatic Coins

# 2020-02-12

## Changed

* Allow Numismatic resource edit form select box values to be cleared.

# 2020-02-12

## Changed

* Increased the load speed of numismatics issue edit pages by using
* Solr queries to populate select boxes.

# 2020-02-11

## Added

* Numismatic Issue forms now have autocompletion and selection for the fields
  Object Type, Denomination, Metal, Shape, Color, and Edge.

# 2020-02-11

## Fixed

* Ruler/Master in Numismatic Issues now has a dropdown for People.

# 2020-02-10

## Fixed

* Allows staff users to access numismatics typeahead dropdowns in forms.

# 2020-02-05

## Added

* PUO Recordings now display multiple days in one Recording.

# 2020-02-04

## Fixed

* Events for Ephemera Folders now include the collections they're a member of,
fixing DPUL Synchronization for those.

# 2020-02-03

## Added

* Ajax-powered select elements for numismatic issues and coins.

# 2020-01-31

## Added

* Added structure editor to Recordings to support Princeton University Orchestra
  use cases.

# 2020-01-06

## Fixed

* Ensures that titles for all numismatic resources are indexed.

# 2020-01-03

## Fixed

* Restored directory browsing for the File Manager interface (this was breaking,
  as users could no longer expand a directory in order to browse its contents
  for file uploads).

## Added

* Users now select monograms from a gallery UI component when they create or edit a numismatic issue

* Added Collection membership to Ephemera folders

# 2020-01-02

## Fixed

* Ensuring that Numismatic Issue facet links in the dashboard interface are
  properly structured

# 2019-12-16

## Fixed

* Google Drive uploads should now work for directories with over 500 contained
  entries (and generally have improved performance)

# 2019-12-11

## Fixed

* Updated browse-everything in order to provide access to shared Google Drive
 items

# 2019-12-09

## Fixed

* Alert messages are no longer hidden by the banner.

# 2019-11-19

## Added

* OAI-PMH endpoint implemented at `/oai` for synchronization with Getty of our
MARC items. Currently only the marc21 `metadata_prefix` is supported.

# 2019-11-18

## Fixed

* Gracefully handling error reporting when an EAD can't be found for an item linked to PULFA.

# 2019-11-12

## Fixed

* Fixes a problem with Google Drive uploads in which authorization headers were
  not being passed to the PendingUpload Resources.

# 2019-11-8

## Fixed

* Ensure that Scanned Map children in MapSets are suppressed in GeoBlacklight.

# 2019-11-8

## Fixed

* Remove WFS endpoints from raster resource geoblacklight documents.
* Add WCS endpoints to raster resource documents.

# 2019-11-7

## Fixed

* Allow anonymous download of audio resource streams with token.

# 2019-10-28

## Added

* Added filename in numismatics manager.

# 2019-10-23

## Fixed

* Removed the IIIF viewer download drop-down menu for non-downloadable public resources.
* Anonymous downloads are disabled for non-downloadable public resources.

# 2019-10-18

## Fixed

* Fixes stale object errors for raster and vector resource derivatives.

# 2019-10-18

## Added

* Automatically adding links to Figgy objects to finding aids as DAO elements.
* Exporting collections as PDFs.

# 2019-10-16

## Added

* Figgy resources are now preserved by default

# 2019-10-14

## Added

* Ephemera Projects can now have "contributors" assigned, who have permission to
create/edit folders and boxes only in that Project.

# 2019-10-10

## Fixed

* Fixed issue where some scanned map geoblacklight documents don't have dates.

# 2019-10-09

## Added

* Added keywords as an available field to Ephemera Folders

# 2019-10-07

## Fixed

* Fixed error where bounding box widget was not rendering on geo resources.

# 2019-10-04

## Fixed

* Fixed bug with generating formatted issue date values in GeoBlacklight documents.

# 2019-10-02

## Added

* Added rake task to run a cloud fixity check on a single resource.

# 2019-09-27

## Added

* Adding HathiTrust submission-information-package creator to exporters.


# 2019-09-26

## Fixed

* Fixed error with Universal Viewer / OpenSeadragon  attempting to load zero-dimension images.

# 2019-09-26

## Added

* Scanned map thumbnail images can now be chosen from a dropdown on the edit
  page.

# 2019-09-16

## Added

* Updating imported metadata from PULFA nightly.

# 2019-09-12

## Fixed

* Viewer no longer pushes buttons to the next line when there are long page
titles.

# 2019-09-06

## Added

* Visibility can now be edited with Bulk Edit
* Start running daily fixity checks on a random subset of resources preserved in the cloud.

# 2019-09-03

## Added

* Preserved FileSets can be reinstated from the File Manager after delete.

## Fixed

* Fixed error downloading PDFs for Ephemera

# 2019-08-20

## Changed

* Changed label of collection field "Slug" to "DPUL URL" for clarity.

* Archival Media Resources import with rights statement "Copyright Not
  Evaluated"

# 2019-08-19

## Changed

* OCR jobs no longer hold up other processing.

# 2019-08-12

## Added

* Displaying Creator in search results, and adding ability to filter by visibility.

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
* Ensure that cases where thumbnails cannot be resolved for resources are handle with attempts to load thumbnails from any members

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
