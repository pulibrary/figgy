# frozen_string_literal: true
class FileSetDecorator < Valkyrie::ResourceDecorator
  self.display_attributes += [:height, :width, :mime_type, :size, :md5, :sha1, :sha256]
  def manageable_files?
    false
  end
end
