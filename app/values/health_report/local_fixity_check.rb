# frozen_string_literal: true
# Checks that local fixity checks for all sub-files are reporting success.
class HealthReport::LocalFixityCheck
  def self.for(resource)
    new(resource: resource)
  end

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def valid?
    true
  end

  def type
    I18n.t("health_status.local_fixity_check.type")
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
    # this count will include events with status "REPAIRING", which will thereby
    # add to the "in_progress" count.
    unknown_count = wayfinder.deep_file_set_count - wayfinder.deep_failed_local_fixity_count - wayfinder.deep_succeeded_local_fixity_count
    @local_fixity_map ||=
      begin
        m = {}
        m[0] = wayfinder.deep_failed_local_fixity_count if wayfinder.deep_failed_local_fixity_count.positive?
        m[1] = wayfinder.deep_succeeded_local_fixity_count if wayfinder.deep_succeeded_local_fixity_count.positive?
        m[nil] = unknown_count if unknown_count.positive?
        m
      end
  end

  def summary
    I18n.t("health_status.local_fixity_check.summary.#{status}")
  end

  private

    def wayfinder
      @wayfinder ||= Wayfinder.for(resource)
    end
end
