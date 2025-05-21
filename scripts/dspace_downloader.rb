# frozen_string_literal: true

require_relative "../config/application"

# Get all resources
class Fetcher
  delegate :get, to: :client
  attr_reader :ark, :dspace_token
  def initialize(ark, dspace_token)
    @ark = ark
    @dspace_token = dspace_token
  end

  def client
    @client ||= Faraday.new(
      "https://dataspace.princeton.edu",
      params: {
        "expand" => "all"
      },
      headers: {
        "rest-dspace-token" => dspace_token
      }
    ) do |builder|
      builder.request :json
      builder.response :json
    end
  end

  def bitstream_client
    @bitstream_client ||= Faraday.new(
      "https://dataspace.princeton.edu",
      headers: {
        "rest-dspace-token" => dspace_token
      }
    )
  end

  def resource
    @resource ||= Resource.new(response, self)
  end

  def response
    rest_data.body
  end

  def rest_data
    @rest_data ||= client.get("/rest/handle/#{ark}")
  end

  class Resource
    attr_reader :resource_data, :client
    def initialize(resource_data, client)
      @resource_data = resource_data
      @client = client
    end

    def reload_data!
      resource_url = resource_data["link"]
      response = client.get(resource_url)
      @resource_data = response.body
    end

    def metadata
      entries = resource_data["metadata"] || []
      grouped = entries.group_by { |x| x["key"] }
      pairs = grouped.map { |k, v| [k.sub("dc.", ""), v.flat_map { |x| x["value"] }] }
      pairs.to_h
    end

    def dir
      ark_ending
    end

    def handle
      resource_data["handle"]
    end

    def name
      resource_data["name"]
    end

    def title
      Array.wrap(metadata["title"]).first
    end

    def ark
      "http://arks.princeton.edu/ark:/#{handle}"
    end

    def ark_ending
      segments = handle.split("/")
      segments.last
    end

    def items
      @items ||= resource_data["items"].map do |item|
        Resource.new(item, client)
      end
    end

    def bitstreams
      bitstreams = (resource_data["bitstreams"] || []).map do |bitstream|
        Bitstream.new(bitstream)
      end

      bitstreams.reject do |b|
        excluded_bitstreams.include?(b.name)
      end
    end

    # Probably missing files?
    # Maybe just skip license.txt
    # TODO: Don't ignore files. Only ignore license.txt.
    def excluded_bitstreams
      [
        "license.txt",
      ]
    end
  end
end

class Bitstream
  attr_reader :data
  def initialize(data)
    @data = data
  end

  def name
    Array.wrap(data["name"]).first
  end

  def filename
    name.downcase
  end

  def extension
    Pathname.new(filename).extname
  end

  def name_no_extension
    Pathname.new(filename).sub_ext("").to_s
  end

  def retrieve_link
    data["retrieveLink"]
  end

  def description
    data["description"]
  end

  def folder_name
    description.presence || name_no_extension
  end

  def sequence_id
    # Zero pad so it sorts.
    data["sequenceId"].to_s.rjust(3, "0")
  end
end

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

  def download_item(item)
    # If the ark mapping has a key, put it in the right space.
    mms_id = Array.wrap(ark_mapping[item.handle]).first
    item_path = if mms_id
                  mapped_dir.join(mms_id)
                else
                  unmapped_dir.join(item.ark_ending)
                end
    # We've done this one - skip it
    if File.exist?(item_path.join("figgy_metadata.json"))
      return
    end
    # If we were unmapped before, and mapped now, move all the files.
    if mms_id && File.exist?(unmapped_dir.join(item.ark_ending))
      puts "Moving previously unmapped #{item.title}"
      FileUtils.mkdir_p(item_path.dirname)
      FileUtils.mv(unmapped_dir.join(item.ark_ending), item_path)
    end
    item.reload_data!
    # If it's one bitstream, put it right in the dir.
    if item.bitstreams.length == 1
      download_bitstream(item, item_path, item.bitstreams.first)
    elsif item.bitstreams.length == 0
      puts "No bitstreams for #{item.handle} #{item.title}. #{item.resource_data["bitstreams"].map{|x| x["name"]}}"
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

  def mapped_dir
    collection_dir.join("mapped")
  end

  def unmapped_dir
    collection_dir.join("unmapped")
  end

  def progress_bar
    @progress_bar ||= ProgressBar.create format: "%a %e %P% Resources Processed: %c of %C", total: collection_resource.items.length
  end

  def download_bitstream(item, item_path, bitstream)
    FileUtils.mkdir_p(item_path)
    bitstream_path = item_path.join(bitstream.filename)
    return if File.exist?(bitstream_path)
    resp = item.client.bitstream_client.get("rest/#{bitstream.retrieve_link}")
    puts "Broken Link!" unless resp.success?
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
      Fetcher.new(collection_handle, dspace_token)
    end

    def collection_resource
      @collection_resource ||= fetched_collection.resource
    end
end

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

  def download_item(item)
    item.reload_data!
    item_dir_name = if collection_mms_id.nil?
                 begin
                   item_mms_id = find_mms_id(item: item)
                 rescue StandardError => item_error
                   puts "Failed to retrieve the MMS ID for #{item.title} (#{item.handle}): #{item_error.message}"
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
      puts "Previously downloaded the item: #{item.title} (#{item.handle}) with MMS ID: #{item_mms_id} to #{item_path}"
    end

    if item.bitstreams.empty?
      raise(StandardError, "Failed to retrieve the bitstreams for #{item.handle} #{item.title}. #{item.resource_data["bitstreams"].map{|x| x["name"]}}")
    end

    puts "Downloading item: #{item.title} (#{item.handle}) with MMS ID: #{item_mms_id}..."

    figgy_metadata = item.metadata
    item.bitstreams.each do |bitstream|
      download_bitstream(item, item_path, bitstream)

      File.open(metadata_path, "w") do |f|
        f.write(figgy_metadata.to_json)
      end
    end
  end

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
downloader = CollectionDownloader.new("88435/dsp01jm214r79v", dspace_token)
downloader.download_all!

# Serial Collections
## Publicly Accessible
### Cases where collections (and not items) have mapped MMS IDs.
### https://dataspace.princeton.edu/handle/88435/dsp01jm214r79v


