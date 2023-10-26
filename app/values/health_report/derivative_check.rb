# frozen_string_literal: true
class HealthReport::DerivativeCheck
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
    I18n.t("health_status.derivative_check.type")
  end

  def status
    @status ||=
      if resource.is_a?(FileSet)
        file_set_status
      elsif children_errored?
        :needs_attention
      elsif children_processing?
        :in_progress
      else
        :healthy
      end
  end

  def file_set_status
    if resource.error_message.present?
      :needs_attention
    elsif resource.processing_status == "in process"
      :in_progress
    else
      :healthy
    end
  end

  def summary
    if resource.respond_to?(:member_ids)
      I18n.t("health_status.derivative_check.summary.#{status}")
    else
      I18n.t("health_status.derivative_check.summary.self.#{status}")
    end
  end

  private

    def children_errored?
      query_service.custom_queries.find_deep_errored_file_sets(resource: resource).positive?
    end

    def children_processing?
      InProcessOrPending.for(resource)
    end

    def query_service
      ChangeSetPersister.default.query_service
    end
end
