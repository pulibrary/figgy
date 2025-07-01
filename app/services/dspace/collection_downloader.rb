# frozen_string_literal: true

module Dspace
  class CollectionDownloader < Downloader
    def find_mms_id(item:)
      item_handle = item.handle
      values = Array.wrap(ark_mapping[item_handle])
      raise(StandardError, "Failed to find the mapped ARK for Item: #{item_handle}") if values.empty?

      values.first
    end

    def collection_mms_id
      @collection_mms_id ||= begin
                               collection_handle = collection_resource.handle
                               values = Array.wrap(ark_mapping[collection_handle])
                               values.first
                             end
    end

    def collection_title
      value = collection_resource.name
      raise(StandardError, "Failed to find the title for Collection: #{collection_resource.handle}: #{collection_resource.resource_data}") if value.blank?

      value
    end

    def collection_dir
      dir_name = collection_mms_id || collection_title
      export_dir.join(dir_name)
    end

    def download_bitstream(item, item_path, bitstream)
      bitstream_path = item_path.join(bitstream.filename)
      return if File.exist?(bitstream_path)

      response = item.client.bitstream_client.get("rest/#{bitstream.retrieve_link}")
      raise(StandardError, "Failed to download bitstream: #{bitstream.retrieve_link}") unless response.success?

      File.open(bitstream_path, "wb") do |f|
        f.write(response.body)
      end
    end

    # rubocop:disable Metrics/AbcSize
    def download_item(item)
      item.reload_data!
      item_dir_name = if collection_mms_id.nil?
                        begin
                          item_mms_id = find_mms_id(item: item)
                        rescue StandardError => item_error
                          Rails.logger.debug "Failed to retrieve the MMS ID for #{item.title} (#{item.handle}): #{item_error.message}"
                          return
                        end

                        item_mms_id
                      else
                        item.title
                      end

      item_path = collection_dir.join(item_dir_name)
      FileUtils.mkdir_p(item_path)

      metadata_path = item_path.join("figgy_metadata.json")
      # We've done this one - skip it
      if File.exist?(metadata_path)
        Rails.logger.debug "Previously downloaded the item: #{item.title} (#{item.handle}) with MMS ID: #{item_mms_id} to #{item_path}"
      end

      if item.bitstreams.empty?
        raise(StandardError, "Failed to retrieve the bitstreams for #{item.handle} #{item.title}. #{item.resource_data['bitstreams'].map { |x| x['name'] }}")
      end

      Rails.logger.debug "Downloading item: #{item.title} (#{item.handle}) with MMS ID: #{item_mms_id}..."

      figgy_metadata = item.metadata
      item.bitstreams.each do |bitstream|
        download_bitstream(item, item_path, bitstream)

        File.open(metadata_path, "w") do |f|
          f.write(figgy_metadata.to_json)
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    # Create the collection directory using the collection title
    def download_all!
      FileUtils.mkdir_p(collection_dir)
      progress_bar
      Parallel.each(collection_resource.items, in_threads: 10) do |item|
        download_item(item)
        progress_bar.progress += 1
      end
    end
  end
end
