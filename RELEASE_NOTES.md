<!--

Release notes template:

# 2019-07-26

## Added

## Fixed

## Changed

## Removed

-->
# 2019-08-06

## Fixed

* Users should now be prevented from submitting multiple Order Manager updates before the initial update has successfully updated the Resource

* The file upload interface should now filter hidden files on the file system within the File Manager for Resources

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
