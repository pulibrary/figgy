# frozen_string_literal: true
class DeletedFileMetadataValidator < ActiveModel::Validator
  def validate(record)
    return if record.delete_file_metadata_ids.blank?
    # Only allow captions to be deleted
    return if deleted_file_metadata_candidates(record).all?(&:caption?)
    record.errors.add :delete_file_metadata_ids, "must reference only captions to delete."
  end

  def deleted_file_metadata_candidates(record)
    record.file_metadata.select do |file_metadata|
      record.delete_file_metadata_ids.include?(file_metadata.id)
    end
  end
end
