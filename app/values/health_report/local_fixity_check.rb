# frozen_string_literal: true
class HealthReport::LocalFixityCheck
  def self.for(resource)
    new(resource: resource)
  end

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def status
    @status ||=
      if Wayfinder.for(resource).try(:deep_failed_local_fixity_count)&.positive?
        :needs_attention
      else
        :healthy
      end
  end
end
