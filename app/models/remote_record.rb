# frozen_string_literal: true
class RemoteRecord
  # Factory method for PulMetadataServices objects
  # @param source_metadata_identifier [String]
  # @param resource [Resource]
  # @return [RemoteRecord, RemoteRecord::PulfaRecord]
  def self.retrieve(source_metadata_identifier, resource: nil)
    if catalog?(source_metadata_identifier)
      Catalog.new(source_metadata_identifier)
    elsif pulfa?(source_metadata_identifier)
      PulfaRecord.new(source_metadata_identifier)
    end
  end

  # Determines whether or not a remote metadata identifier is an identifier for catalog records
  # @param source_metadata_id [String] the remote metadata identifier
  # @return [Boolean]
  # @see # https://lib-confluence.princeton.edu/display/ALMA/Alma+System+Numbers
  def self.catalog?(source_metadata_id)
    # 99*6421 will be in all alma IDs
    return unless source_metadata_id.to_s.length > 9 && source_metadata_id.to_s.start_with?("99")
    source_metadata_id =~ /\A\d+\z/
  end

  def self.pulfa?(source_metadata_identifier)
    return false if source_metadata_identifier.match?(/\//)
    source_metadata_identifier.match?(/^(aspace_)?([A-Z][a-zA-Z0-9\.-]+)(_[a-z0-9]+)?/)
  end

  def self.pulfa_collection(source_metadata_identifier)
    return if source_metadata_identifier.match?(/\//)
    m = source_metadata_identifier.match(/^(aspace_)?(?<code>[A-Z][a-zA-Z0-9.-]+)([_][a-z0-9]+)?/)
    m[:code] if m
  end

  def self.pulfa_component(source_metadata_identifier)
    return if source_metadata_identifier.match?(/\//)
    return unless source_metadata_identifier.match?(/_/)
    m = source_metadata_identifier.match(/^[A-Z][a-zA-Z0-9.-]+_([a-z0-9]+)/)
    m[1] if m
  end

  def self.valid?(source_metadata_identifier)
    catalog?(source_metadata_identifier) || pulfa?(source_metadata_identifier)
  end

  def self.source_metadata_url(id)
    return "#{Figgy.config[:catalog_url]}#{id}.marcxml" if catalog?(id)
    "#{Figgy.config[:findingaids_url]}#{id.tr('/', '_')}.xml" if pulfa?(id)
  end

  def self.record_url(id)
    return unless id
    return "https://catalog.princeton.edu/catalog/#{id}" if catalog?(id)
    "#{Figgy.config[:findingaids_url]}#{id.tr('/', '_').tr('.', '-')}" if pulfa?(id)
  end
end
