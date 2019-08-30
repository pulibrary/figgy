# frozen_string_literal: true
class EphemeraFolderChangeSet < EphemeraFolderChangeSetBase
  def self.new(record, *args)
    return ChangeSet.for(record, *args) unless record.is_a?(EphemeraFolder)
    super
  end

  validates :barcode, :folder_number, :title, :language, :genre, :width, :height, :page_count, :visibility, presence: true

  property :barcode, multiple: false, required: true
  property :folder_number, multiple: false, required: true
  property :width, multiple: false, required: true
  property :height, multiple: false, required: true
end
