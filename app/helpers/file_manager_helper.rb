# frozen_string_literal: true

module FileManagerHelper
  def geo_metadata_file?(change_set)
    original_file = change_set.model.try(:original_file)
    return false unless original_file
    ControlledVocabulary.for(:geo_metadata_format).include?(original_file.mime_type.first)
  end
end
