# frozen_string_literal: true
class ResourceDetector
  def self.viewable_resource?(resource)
    resource.respond_to?(:member_ids) && resource.respond_to?(:thumbnail_id)
  end

  def self.file_metadata?(resource)
    !resource.respond_to?(:file_metadata) && resource.respond_to?(:original_filename)
  end

  def self.file_set?(resource)
    resource.respond_to?(:file_metadata) && !resource.respond_to?(:member_ids)
  end
end
