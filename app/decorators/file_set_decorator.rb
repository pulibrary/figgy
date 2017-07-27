# frozen_string_literal: true
class FileSetDecorator < Valkyrie::ResourceDecorator
  def manageable_files?
    false
  end
end
