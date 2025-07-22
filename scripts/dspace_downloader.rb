# frozen_string_literal: true

# Run this script with `DSPACE_TOKEN=<token> rails runner scripts/dspace_downloader.rb`

# Get all resources

# Monograph Collections
# Public one
logger = Logger.new(STDOUT)
logger.info "Downloading public monographs"
Dspace::Downloader.new(collection_handle: "88435/dsp016q182k16g", dspace_token: ENV["DSPACE_TOKEN"], logger: logger).download_all!
# Private one.
logger.info "Downloading private monographs"
Dspace::Downloader.new(collection_handle: "88435/dsp01bg257f09p", dspace_token: ENV["DSPACE_TOKEN"], logger: logger).download_all!

# Serials
## Public
logger.info "Downloading public serials"
Dspace::Downloader.new(collection_handle: "88435/dsp01jm214r79v", dspace_token: dspace_token, logger: logger).download_all!
## Private
logger.info "Downloading private serials"
Dspace::Downloader.new(collection_handle: "88435/dsp01r781wg06f", dspace_token: dspace_token, logger: logger).download_all!
