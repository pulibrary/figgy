# frozen_string_literal: true
class BoxlessEphemeraFolderChangeSet < EphemeraFolderChangeSetBase
  def self.new(record, *args)
    return ChangeSet.for(record, *args) unless record.is_a?(EphemeraFolder)
    super
  end

  validates :title, :language, :genre, :page_count, :visibility, presence: true

  property :barcode, multiple: false, required: false
  property :folder_number, multiple: false, required: false
  property :width, multiple: false, required: false
  property :height, multiple: false, required: false
end
