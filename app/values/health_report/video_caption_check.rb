# frozen_string_literal: true
class HealthReport::VideoCaptionCheck
  def self.for(resource)
    new(resource: resource)
  end

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def valid?
    if file_set?
      resource.video?
    else
      video_members_count.positive?
    end
  end

  def type
    I18n.t("health_status.video_caption_check.type")
  end

  def status
    @status ||=
      if file_set?
        file_set_status
      elsif uncaptioned_members.length.positive?
        :needs_attention
      else
        :healthy
      end
  end

  def file_set_status
    if resource.missing_captions?
      :needs_attention
    else
      :healthy
    end
  end

  def summary
    if resource.respond_to?(:member_ids)
      I18n.t("health_status.video_caption_check.summary.#{status}")
    else
      I18n.t("health_status.video_caption_check.summary.self.#{status}")
    end
  end

  def query_service
    ChangeSetPersister.default.query_service
  end

  def uncaptioned_members
    @uncaptioned_members ||= query_service.custom_queries.find_uncaptioned_members(resource: resource)
  end

  def video_members_count
    @video_members_count ||= query_service.custom_queries.find_video_members(resource: resource, count: true)
  end

  def file_set?
    resource.is_a?(FileSet)
  end

  def unhealthy_resources
    []
  end
end
