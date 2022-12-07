# frozen_string_literal: true
module FileManagerHelper
  def geo_metadata_file?(change_set)
    primary_file = change_set.model.try(:primary_file)
    return false unless primary_file
    ControlledVocabulary.for(:geo_metadata_format).include?(primary_file.mime_type.first)
  end
end
