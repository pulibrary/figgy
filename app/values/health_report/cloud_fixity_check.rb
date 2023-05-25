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

  def summary
    I18n.t("health_status.cloud_fixity_check.summary.#{status}")
  end

  def type
    I18n.t("health_status.cloud_fixity_check.type")
  end

  private

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
