# frozen_string_literal: true

# Class for Apache Tika based file characterization service
# defines the Apache Tika based characterization service a ValkyrieFileCharacterization service
# @since 0.1.0
class DefaultCharacterizationService
  attr_reader :file_node, :persister
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
    ImagemagickCharacterizationService.new(file_node: file_node, persister: persister).characterize
  end

  def valid?
    !parent.respond_to?(:geo_resource?) || !parent.geo_resource?
  end

  def parent
    file_node.decorate.parent
  end
end
