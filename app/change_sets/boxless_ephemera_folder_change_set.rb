# frozen_string_literal: true
class BoxlessEphemeraFolderChangeSet < EphemeraFolderChangeSet
  def self.new(record, *args)
    return DynamicChangeSet.new(record, *args) unless record.is_a?(EphemeraFolder)
    super
  end

  validates :title, :language, :genre, :width, :height, :page_count, :visibility, :rights_statement, presence: true
  property :barcode, multiple: false, required: false
  property :folder_number, multiple: false, required: false
end
