# frozen_string_literal: true
class HealthReport::CloudFixityCheck
  def self.for(resource)
    new(resource: resource)
  end

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def status
    @status ||=
      if Wayfinder.for(resource).try(:deep_failed_cloud_fixity_count)&.positive?
        :needs_attention
      else
        :healthy
      end
  end

  def type
    I18n.t("health_status.cloud_fixity_check.type")
  end

  def summary
    I18n.t("health_status.cloud_fixity_check.summary.#{status}")
  end
end
