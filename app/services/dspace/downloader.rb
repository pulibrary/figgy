# frozen_string_literal: true

module Dspace
  class Downloader
    attr_reader :collection_handle, :dspace_token
    def initialize(collection_handle, dspace_token, ark_mapping = nil)
      @collection_handle = collection_handle
      @dspace_token = dspace_token
      @ark_mapping = ark_mapping
    end

    def download_all!
      FileUtils.mkdir_p(collection_dir)
      progress_bar
      Parallel.each(collection_resource.items, in_threads: 10) do |item|
        download_item(item)
        progress_bar.progress += 1
      end
    end

    def ark_mapping_path
      Rails.root.join("scripts", "dspace_mms_to_ark.csv")
    end

    def ark_mapping
      @ark_mapping ||= begin
                         entries = CSV.read(ark_mapping_path)
                         grouped = entries.group_by(&:last)
                         pairs = grouped.map { |k, v| [k, v.flat_map(&:first).uniq] }
                         pairs.to_h
                       end
    end

    def collection_dir
      export_dir.join(collection_resource.ark_ending)
    end

    # rubocop:disable Metrics/AbcSize
    def download_item(item)
      # If the ark mapping has a key, put it in the right space.
      mms_id = Array.wrap(ark_mapping[item.handle]).first
      item_path = if mms_id
                    collection_dir.join(mms_id)
                  else
                    collection_dir.join(item.name)
                  end
      # We've done this one - skip it
      if File.exist?(item_path.join("figgy_metadata.json"))
        return
      end
      item.reload_data!
      # If it's one bitstream, put it right in the dir.
      if item.bitstreams.length == 1
        download_bitstream(item, item_path, item.bitstreams.first)
      elsif item.bitstreams.empty?
        Rails.logger.debug "No bitstreams for #{item.handle} #{item.title}. #{item.resource_data['bitstreams'].map { |x| x['name'] }}"
        return
      else
        item.bitstreams.each do |bitstream|
          sub_path = item_path.join("#{bitstream.sequence_id} - #{bitstream.folder_name}")
          download_bitstream(item, sub_path, bitstream)
        end
      end
      File.open(item_path.join("figgy_metadata.json"), "w") do |f|
        f.write({ identifier: item.ark }.to_json)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def progress_bar
      @progress_bar ||= ProgressBar.create format: "%a %e %P% Resources Processed: %c of %C", total: collection_resource.items.length
    end

    def download_bitstream(item, item_path, bitstream)
      FileUtils.mkdir_p(item_path)
      bitstream_path = item_path.join(bitstream.filename)
      return if File.exist?(bitstream_path)
      resp = item.client.bitstream_client.get("rest#{bitstream.retrieve_link}")
      Rails.logger.debug "Broken Link!" unless resp.success?
      return unless resp.success?
      File.open(bitstream_path, "wb") do |f|
        f.write resp.body
      end
    end

    def dspace_config
      Figgy.config["dspace"]
    end

    def download_path
      dspace_config["download_path"]
    end

    def export_dir
      Pathname.new(download_path.to_s)
    end

    private

      def fetched_collection
        Client.new(collection_handle, dspace_token)
      end

      def collection_resource
        @collection_resource ||= fetched_collection.resource
      end
  end
end
