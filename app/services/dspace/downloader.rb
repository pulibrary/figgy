# frozen_string_literal: true

module Dspace
  class Downloader
    attr_reader :collection_handle, :dspace_token, :progress, :logger, :parent_title, :order_items
    def initialize(collection_handle:, dspace_token:, collection_dir: nil, collection_resource: nil, ark_mapping: nil, progress: nil, logger: Rails.logger, order_items: false)
      @collection_handle = collection_handle
      @dspace_token = dspace_token
      @ark_mapping = ark_mapping
      @progress = progress
      @collection_dir = collection_dir
      @collection_resource = collection_resource
      @parent_title = self.collection_resource.title
      @logger = logger
      @order_items = order_items
    end

    def download_all!
      FileUtils.mkdir_p(collection_dir)
      progress_bar unless progress
      Parallel.each_with_index(collection_resource.items, in_threads: 10) do |item, idx|
        begin
          download_item(item, idx)
        rescue StandardError => e
          FileUtils.rm_rf(item_path(item))
          logger.info "Failed to download #{item.handle} - #{e.message}"
        end
        progress_bar.progress += 1 unless progress
      end
      Parallel.each(collection_resource.collections, in_threads: 10) do |item|
        download_item(item, nil)
        progress_bar.progress += 1 unless progress
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
      @collection_dir ||= export_dir.join(collection_resource.ark_ending)
    end

    def mms_id(item)
      Array.wrap(ark_mapping[item.handle]).first.to_s.gsub(/[^0-9]/, "").presence
    end

    def item_path(item, idx = nil)
      # If the ark mapping has a key, put it in the right space.
      mms_id = self.mms_id(item)
      dir_name = ""
      # Sort by accessioned date if we got it, otherwise use idx.
      dir_name += "#{item.inverse_accessioned_date_timestamp&.to_s&.rjust(13, '0') || (idx + 1).to_s.rjust(3, '0')}-" if order_items
      dir_name += "#{item.id}-"
      dir_name += if mms_id
                    mms_id.to_s
                  else
                    item.dir_name(parent_title)
                  end
      collection_dir.join(dir_name)
    end

    # rubocop:disable Metrics/AbcSize
    def download_item(item, idx)
      item.reload_data! if order_items # We need accessioned_date :(
      item_path = item_path(item, idx)
      # We've done this one - skip it
      if File.exist?(item_path.join("figgy_metadata.json"))
        return
      end
      item.reload_data! unless order_items
      # Ingesting a collection - launch a sub-downloader.
      if item.type == "collection"
        FileUtils.mkdir_p(item_path)
        write_metadata(item, item_path)
        Downloader.new(collection_handle: item.handle, order_items: true, dspace_token: dspace_token, collection_dir: item_path, collection_resource: item, ark_mapping: ark_mapping,
                       logger: logger).download_all!
      else
        # If it's one bitstream, put it right in the dir.
        if item.bitstreams.length == 1
          download_bitstream(item, item_path, item.bitstreams.first)
        elsif item.bitstreams.empty?
          logger.info "No bitstreams for #{item.handle} #{item.title}. #{(item.resource_data['bitstreams'] || []).map { |x| x['name'] }}"
          FileUtils.rm_rf(item_path)
          return
        else
          item.bitstreams.each do |bitstream|
            sub_path = item_path.join("#{bitstream.sequence_id} - #{bitstream.folder_name}")
            FileUtils.mkdir_p(sub_path)
            write_metadata(bitstream, sub_path)
            download_bitstream(item, sub_path, bitstream)
          end
        end
        write_metadata(item, item_path)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def write_metadata(item, item_path)
      mms_id = self.mms_id(item)
      File.open(item_path.join("figgy_metadata.json"), "w") do |f|
        f.write({ title: item.title, source_metadata_identifier: mms_id, identifier: item.ark, local_identifier: [item.handle, item.id.to_s].select(&:present?) }.compact.to_json)
      end
    end

    def progress_bar
      @progress_bar ||= ProgressBar.create format: "%a %e %P% Resources Processed: %c of %C", total: collection_resource.items.length + collection_resource.collections.length
    end

    def download_bitstream(item, item_path, bitstream)
      FileUtils.mkdir_p(item_path)
      bitstream_path = item_path.join(bitstream.filename)
      return if File.exist?(bitstream_path)
      resp = item.client.bitstream_client.get("rest#{bitstream.retrieve_link}")
      raise "Unable to fetch bitstream #{bitstream.filename}" unless resp.success?
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
