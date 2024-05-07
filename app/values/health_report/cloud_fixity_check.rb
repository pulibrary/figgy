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
      if resource.is_a?(EphemeraProject) || resource.is_a?(FileSet)
        shallow_status
      else
        deep_status
      end
  end

  def summary
    if resource.respond_to?(:member_ids)
      I18n.t("health_status.cloud_fixity_check.summary.#{status}")
    else
      I18n.t("health_status.cloud_fixity_check.summary.self.#{status}")
    end
  end

  def type
    I18n.t("health_status.cloud_fixity_check.type")
  end

  def name
    type.parameterize(separator: "_")
  end

  def unhealthy_resources
    []
  end

  private

    # shallow_status only checks the resource itself.
    def shallow_status
      preservation_object = Wayfinder.for(resource).preservation_object
      return :in_progress unless preservation_object
      events = Wayfinder.for(preservation_object).current_cloud_fixity_events
      if events.count(&:failed?).positive?
        :needs_attention
      elsif events.count(&:repairing?).positive?
        :repairing
      else
        :healthy
      end
    end

    def deep_status
      if wayfinder.deep_failed_cloud_fixity_count.positive?
        :needs_attention
      elsif wayfinder.deep_repairing_cloud_fixity_count.positive?
        :repairing
      elsif unknown_count.positive?
        :in_progress
      else
        :healthy
      end
    end

    def unknown_count
      # There's a bug here in the following case:
      # - The metadata node has been checked but the binary node has not, or
      # vice-versa
      # - OR the resource has 2 preserved binary nodes and one has been checked
      # and the other has not
      #
      # In this case, we will likely get too many successes and obscure an in
      # progress status.
      #
      # However, these checks get queued simultaneously so unless one never runs
      # for some reason, the misinformation will be short-lived.
      @unknown_count ||= wayfinder.deep_file_set_count - wayfinder.deep_failed_cloud_fixity_count - wayfinder.deep_succeeded_cloud_fixity_count - wayfinder.deep_repairing_cloud_fixity_count
    end

    def wayfinder
      @wayfinder ||= Wayfinder.for(resource)
    end
end
