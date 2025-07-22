# frozen_string_literal: true

# Run this script with `DSPACE_TOKEN=<token> rails runner scripts/dspace_downloader.rb`

# Get all resources

# Monograph Collections
# Public one
Dspace::Downloader.new(collection_handle: "88435/dsp016q182k16g", dspace_token: ENV["DSPACE_TOKEN"]).download_all!
# Private one.
Dspace::Downloader.new(collection_handle: "88435/dsp01bg257f09p", dspace_token: ENV["DSPACE_TOKEN"]).download_all!

# Serials
## Public
Dspace::Downloader.new(collection_handle: "88435/dsp01jm214r79v", dspace_token: dspace_token).download_all!
## Private
Dspace::Downloader.new(collection_handle: "88435/dsp01r781wg06f", dspace_token: dspace_token).download_all!
