# frozen_string_literal: true

# Class for characterizatizing scanned maps. Adds processing note.
class ScannedMapCharacterizationService
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
    @file_characterization_attributes = {
      processing_note: processing_note
    }
    new_file = primary_file.new(@file_characterization_attributes.to_h)
    @file_set.file_metadata = @file_set.file_metadata.select { |x| x.id != new_file.id } + [new_file]
    @file_set = @persister.save(resource: @file_set) if save
    @file_set
  end

  def primary_file
    @file_set.primary_file
  end

  def parent
    file_set.decorate.parent
  end

  def processing_note
    Figgy.config["scanned_map_processing_note"]
  end

  def valid?
    parent.is_a?(ScannedMap)
  end
end
