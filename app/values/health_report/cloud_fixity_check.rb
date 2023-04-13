# frozen_string_literal: true
# Checks that cloud fixity has run for all sub-files and that preservation is complete.
class HealthReport::CloudFixityCheck
  def self.for(resource)
    new(resource: resource)
  end

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def valid?
    ChangeSet.for(resource).try(:preserve?)
  end

  def status
    @status ||=
      if fixity_map[0]&.positive?
        :needs_attention
      elsif fixity_map[nil]&.positive?
        :in_progress
      else
        :healthy
      end
  end

  def fixity_map
    return {} unless resource.decorate.respond_to?(:file_sets)
    unknown_count = wayfinder.deep_file_set_count - wayfinder.deep_failed_cloud_fixity_count - wayfinder.deep_succeeded_cloud_fixity_count
    @cloud_fixity_map ||=
      begin
        m = {}
        m[0] = wayfinder.deep_failed_cloud_fixity_count if wayfinder.deep_failed_cloud_fixity_count.positive?
        m[1] = wayfinder.deep_succeeded_cloud_fixity_count if wayfinder.deep_succeeded_cloud_fixity_count.positive?
        m[nil] = unknown_count if unknown_count.positive?
        m
      end
  end

  def wayfinder
    @wayfinder ||= Wayfinder.for(resource)
  end

  def type
    I18n.t("health_status.cloud_fixity_check.type")
  end

  def summary
    I18n.t("health_status.cloud_fixity_check.summary.#{status}")
  end
end
