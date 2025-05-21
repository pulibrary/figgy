# frozen_string_literal: true
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
      @resource_data = client.get(resource_data["link"]).body
    end

    def metadata
      (resource_data["metadata"] || []).group_by { |x| x["key"] }.map { |k, v| [k, v.flat_map { |x| x["value"] }] }.to_h
    end

    def dir
      ark_ending
    end

    def handle
      resource_data["handle"]
    end

    def ark
      "http://arks.princeton.edu/ark:/#{handle}"
    end

    def ark_ending
      handle.split("/").last
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
      bitstreams.select do |b|
        bitstream_extensions.include?(b.extension)
      end
    end

    def bitstream_extensions
      [".pdf", ".jpg", ".png", ".tif", ".TIF", ".tiff", ".TIFF"]
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

  def ark_mapping
    @ark_mapping ||= CSV.read(Rails.root.join("scripts", "dspace_mms_to_ark.csv")).group_by(&:last).map { |k, v| [k, v.flat_map(&:first).uniq] }.to_h
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
      puts "Moving previously unmapped #{item.metadata['dc.title']}"
      FileUtils.mkdir_p(item_path.dirname)
      FileUtils.mv(unmapped_dir.join(item.ark_ending), item_path)
    end
    item.reload_data!
    # If it's one bitstream, put it right in the dir.
    if item.bitstreams.length == 1
      download_bitstream(item, item_path, item.bitstreams.first)
    elsif item.bitstreams.length == 0
      puts "No bitstreams for #{item.handle} #{item.metadata['dc.title']}. #{item.resource_data["bitstreams"].map{|x| x["name"]}}"
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

  def export_dir
    Rails.root.join("tmp").join("dspace_export")
  end

  private

    def collection_resource
      @collection_resource ||= Fetcher.new(collection_handle, dspace_token).resource
    end
end
Downloader.new("88435/dsp016q182k16g", ENV["DSPACE_TOKEN"]).download_all!
