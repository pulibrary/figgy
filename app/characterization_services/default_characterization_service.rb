# frozen_string_literal: true

# Class for Apache Tika based file characterization service
# defines the Apache Tika based characterization service a ValkyrieFileCharacterization service
# @since 0.1.0
class DefaultCharacterizationService
  attr_reader :file_set, :persister
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
    ImagemagickCharacterizationService.new(file_set: file_set, persister: persister).characterize
  end

  def geo_resource?
    parent.respond_to?(:geo_resource?) && parent.geo_resource?
  end

  def media_resource?
    parent.respond_to?(:media_resource?) && parent.media_resource?
  end

  def valid?
    !geo_resource? && !media_resource?
  end

  def parent
    file_set.decorate.parent
  end
end
