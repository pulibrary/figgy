# frozen_string_literal: true

# Class for characterizatizing scanned maps. Adds processing note.
class ScannedMapCharacterizationService
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
    @file_characterization_attributes = {
      processing_note: processing_note
    }
    new_file = original_file.new(@file_characterization_attributes.to_h)
    @file_node.file_metadata = @file_node.file_metadata.select { |x| x.id != new_file.id } + [new_file]
    @persister.save(resource: @file_node) if save
    @file_node
  end

  def original_file
    @file_node.original_file
  end

  def parent
    file_node.decorate.parent
  end

  def processing_note
    Figgy.config["scanned_map_processing_note"]
  end

  def valid?
    parent.is_a?(ScannedMap)
  end
end
