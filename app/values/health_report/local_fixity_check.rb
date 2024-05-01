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

  def check_name
    type.parameterize(separator: "-")
  end

  def status
    @status ||=
      if resource.is_a?(EphemeraProject)
        # Don't check ephemera projects deep, and they don't have any files, so
        # there's no fixity to check.
        :healthy
      else
        deep_status
      end
  end

  def summary
    if resource.respond_to?(:member_ids)
      I18n.t("health_status.local_fixity_check.summary.#{status}")
    else
      I18n.t("health_status.local_fixity_check.summary.self.#{status}")
    end
  end

  def unhealthy_resources
    []
  end

  private

    def deep_status
      if wayfinder.deep_failed_local_fixity_count.positive?
        :needs_attention
      elsif wayfinder.deep_repairing_local_fixity_count.positive?
        :repairing
      elsif unknown_count.positive?
        :in_progress
      else
        :healthy
      end
    end

    def unknown_count
      # There's a bug here in the following case:
      # - the resource has 2 preserved binary nodes and one has been checked
      # and the other has not
      #
      # In this case, we will likely get too many successes and obscure an in
      # progress status.
      #
      # However, these checks get queued simultaneously so unless one never runs
      # for some reason, the misinformation will be short-lived.
      @unknown_count ||= wayfinder.deep_file_set_count - wayfinder.deep_failed_local_fixity_count - wayfinder.deep_succeeded_local_fixity_count - wayfinder.deep_repairing_local_fixity_count
    end

    def wayfinder
      @wayfinder ||= Wayfinder.for(resource)
    end
end
