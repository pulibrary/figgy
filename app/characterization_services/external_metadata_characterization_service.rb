# frozen_string_literal: true

# Class for characterizing exeternal geo metadata files
class ExternalMetadataCharacterizationService
  attr_reader :file_set, :persister
  delegate :mime_type, to: :primary_file
  def initialize(file_set:, persister:)
    @file_set = file_set
    @persister = persister
  end

  # characterizes the file_set passed into this service
  # Default options are:
  #   save: true
  # @param save [Boolean] should the persister save the file_set after Characterization
  # @return [FileNode]
  # @example characterize a file and persist the changes by default
  #   Valkyrie::Derivatives::FileCharacterizationService.for(file_set, persister).characterize
  # @example characterize a file and do not persist the changes
  #   Valkyrie::Derivatives::FileCharacterizationService.for(file_set, persister).characterize(save: false)
  def characterize(save: true)
    primary_file.mime_type = geo_mime_type
    @file_set = @persister.save(resource: @file_set) if save
    @file_set
  end

  def geo_mime_type
    return "application/xml; schema=fgdc" if fgdc?
    return "application/xml; schema=iso19139" if iso19139?
    mime_type
  end

  def fgdc?
    !document.at_xpath("//metadata/idinfo").nil?
  end

  def iso19139?
    !document.at_xpath("//gmd:metadataStandardName", ISO_NAMESPACE).nil?
  end

  ISO_NAMESPACE = {
    "xmlns:gmd" => "http://www.isotc211.org/2005/gmd",
    "xmlns:gco" => "http://www.isotc211.org/2005/gco"
  }.freeze

  def document
    @document ||= Nokogiri::XML(file_object.read)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: primary_file.file_identifiers[0])
  end

  def primary_file
    @file_set.primary_file
  end

  def valid?
    mime_type == ["application/xml"]
  end
end
