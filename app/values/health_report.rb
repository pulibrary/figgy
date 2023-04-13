# frozen_string_literal: true
class HealthReport
  def self.for(resource)
    new(resource: resource)
  end

  def self.check_classes
    [
      LocalFixityCheck,
      CloudFixityCheck
    ]
  end

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def status
    all_check_statuses = checks.map(&:status).uniq
    return all_check_statuses.first if all_check_statuses.length == 1
    all_check_statuses.sort_by { |status| status_weights.fetch(status, 0) }.last
  end

  def checks
    @checks ||=
      self.class.check_classes.map do |check_class|
        check_class.for(resource)
      end
  end

  private

    # Assign each status a weight for sorting, if one check is needs_attention
    # and another is healthy, the overall status should be needs_attention.
    def status_weights
      {
        healthy: 0,
        in_progress: 1,
        needs_attention: 2
      }
    end
end
