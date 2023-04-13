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
    @fixity_map ||= resource.decorate.cloud_fixity_map
  end

  def type
    I18n.t("health_status.cloud_fixity_check.type")
  end

  def summary
    I18n.t("health_status.cloud_fixity_check.summary.#{status}")
  end
end
