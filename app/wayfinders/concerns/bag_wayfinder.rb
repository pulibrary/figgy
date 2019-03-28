# frozen_string_literal: true
module BagWayfinder
  extend ActiveSupport::Concern

  def bag_file_sets
    file_sets.select do |file_set|
      metadata = file_set.file_metadata
      use_metadata = metadata.map(&:use)
      results = use_metadata.map { |use| use.include?(RemoteChecksumService::GoogleCloudStorageFileAdapter.bag_uri) }
      results.reduce(:|)
    end
  end

  def compressed_bag_file_set
    bag_file_sets.find { |file_set| file_set.mime_type & ["application/gzip", "application/zip"] }
  end
end
