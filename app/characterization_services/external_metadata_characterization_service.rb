# frozen_string_literal: true

# Class for characterizing exeternal geo metadata files
class ExternalMetadataCharacterizationService
  attr_reader :file_node, :persister
  delegate :mime_type, to: :original_file
  def initialize(file_node:, persister:)
    @file_node = file_node
    @persister = persister
  end

  # characterizes the file_node passed into this service
  # Default options are:
  #   save: true
  # @param save [Boolean] should the persister save the file_node after Characterization
  # @return [FileNode]
  # @example characterize a file and persist the changes by default
  #   Valkyrie::Derivatives::FileCharacterizationService.for(file_node, persister).characterize
  # @example characterize a file and do not persist the changes
  #   Valkyrie::Derivatives::FileCharacterizationService.for(file_node, persister).characterize(save: false)
  def characterize(save: true)
    original_file.mime_type = geo_mime_type
    @persister.save(resource: @file_node) if save
    @file_node
  end

  def geo_mime_type
    return "application/xml; schema=fgdc" if fgdc?
    return "application/xml; schema=iso19139" if iso19139?
    mime_type
  end

  def fgdc?
    !document.at_xpath('//metadata/idinfo').nil?
  end

  def iso19139?
    !document.at_xpath('//gmd:metadataStandardName', ISO_NAMESPACE).nil?
  end

  ISO_NAMESPACE = {
    'xmlns:gmd' => 'http://www.isotc211.org/2005/gmd',
    'xmlns:gco' => 'http://www.isotc211.org/2005/gco'
  }.freeze

  def document
    @document ||= Nokogiri::XML(file_object.read)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
  end

  def original_file
    @file_node.original_file
  end

  def valid?
    mime_type == ["application/xml"]
  end
end
