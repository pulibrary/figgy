# frozen_string_literal: true
module FileManagerHelper
  def geo_metadata_file?(change_set)
    primary_file = change_set.model.try(:primary_file)
    return false unless primary_file
    ControlledVocabulary.for(:geo_metadata_format).include?(primary_file.mime_type.first)
  end

  def local_fixity_failure_ids
    @local_fixity_failure_ids ||= Wayfinder.for(@change_set.resource).deep_failed_local_fixity_member_ids
  end

  def cloud_fixity_failure_ids
    @cloud_fixity_failure_ids ||= Wayfinder.for(@change_set.resource).deep_failed_cloud_fixity_member_ids
  end
end
