# frozen_string_literal: true

# Run this script with `DSPACE_TOKEN=<token> rails runner scripts/dspace_downloader.rb`

# Get all resources

# Monograph Collections
# Public one
# Downloader.new("88435/dsp016q182k16g", ENV["DSPACE_TOKEN"]).download_all!
# Private one.
# Downloader.new("88435/dsp01bg257f09p", ENV["DSPACE_TOKEN"]).download_all!

# TODO: Add support for collections
# There are collections when `collection_resource["collections"] isn't blank.
# If there's collections, we can't do mapped/unmapped. Just trust the ark
# report.
# Folder structures:
# - <mms-id of collection>
#   - <title of item>
#     - <bitstream.pdf>
#     - figgy_metadata.json
# - <title of collection>
#   - <mms-id of item>
#     - <bitstream.pdf>
#     - figgy_metadata.json
#
# Serial Collections
## Publicly Accessible
### Cases where items (and not collections) have mapped MMS IDs.
### https://dataspace.princeton.edu/handle/88435/dsp01jm214r79v
dspace_token = ENV["DSPACE_TOKEN"]
downloader = Dspace::CollectionDownloader.new("88435/dsp01jm214r79v", dspace_token)
downloader.download_all!

# Serial Collections
## Publicly Accessible
### Cases where collections (and not items) have mapped MMS IDs.
### https://dataspace.princeton.edu/handle/88435/dsp01jm214r79v
