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

  # @return [Array<Hash>] Array of unique parent resource ids, labels, and counts of errored file sets
  def unhealthy_resources
    unhealthy_file_sets.map do |file_set|
      file_set.decorate.parent
    end.uniq(&:id)
  end

  def summary
    I18n.t("health_status.derivative_check.summary.#{status}")
  end

  private

    def children_errored?
      errored_file_sets.count.positive?
    end

    def children_processing?
      in_process_service.call
    end

    def errored_file_sets
      @errored_file_sets ||= query_service.custom_queries.find_deep_errored_file_sets(resource: resource)
    end

    def in_process_file_sets
      in_process_service.in_process_file_sets
    end

    def in_process_service
      @in_process_service ||= InProcessOrPending.new(resource)
    end

    def unhealthy_file_sets
      if children_errored?
        errored_file_sets
      elsif children_processing?
        in_process_file_sets
      else
        []
      end
    end

    def query_service
      ChangeSetPersister.default.query_service
    end
end
