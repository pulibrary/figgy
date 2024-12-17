# frozen_string_literal: true
class RemoteRecord::PulfaRecord
  attr_reader :source_metadata_identifier

  # Constructor
  # @param source_metadata_identifier [String]
  # @param resource [Resource]
  def initialize(source_metadata_identifier)
    @source_metadata_identifier = source_metadata_identifier
  end

  def attributes
    @attributes ||= client_result.attributes.merge(source_metadata: client_result.full_source)
  end

  def success?
    client_result && client_result.source.strip.present?
  end

  def client_result
    @client_result ||= PulMetadataServices::Client.retrieve(source_metadata_identifier)
  end
end
