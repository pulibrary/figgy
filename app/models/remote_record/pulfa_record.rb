# frozen_string_literal: true
# TODO: Call it RemoteMetadata::FindingAids
class RemoteRecord::PulfaRecord
  attr_reader :source_metadata_identifier

  # Constructor
  # @param source_metadata_identifier [String]
  # @param resource [Resource]
  def initialize(source_metadata_identifier)
    @source_metadata_identifier = source_metadata_identifier
  end

  def attributes
    @attributes ||= source_attributes.merge(source_metadata: source)
  end

  def success?
    source&.strip.present?
  end

  def source_attributes
    JSON.parse(source, symbolize_names: true)
  end

  def source
    @source ||= json
  end

  def json
    conn = Faraday.new(url: Figgy.config[:findingaids_url])
    url = "#{source_metadata_identifier.tr('.', '-')}.json"
    url += "?auth_token=#{Figgy.pulfalight_unpublished_token}" if Figgy.pulfalight_unpublished_token.present?
    response = conn.get(url)
    return unless response.success?
    response.body.dup.force_encoding("UTF-8")
  end

  def ead_xml
    conn = Faraday.new(url: Figgy.config[:findingaids_url])
    url = "#{source_metadata_identifier.tr('.', '-')}.xml"
    response = conn.get(url)
    return unless response.success?
    response.body.dup.force_encoding("UTF-8")
  end
end
