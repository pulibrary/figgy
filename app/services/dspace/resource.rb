# frozen_string_literal: true

class Dspace::Resource
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

  def type
    resource_data["type"]
  end

  def id
    resource_data["id"]
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
    @items ||= resource_data.fetch("items", []).map do |item|
      Dspace::Resource.new(item, client)
    end
  end

  def collections
    @collections ||= resource_data.fetch("collections", []).map do |item|
      Dspace::Resource.new(item, client)
    end
  end

  def bitstreams
    bitstreams = (resource_data["bitstreams"] || []).map do |bitstream|
      Dspace::Bitstream.new(bitstream)
    end

    bitstreams.select(&:original?)
  end
end
