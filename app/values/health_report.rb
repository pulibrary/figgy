# frozen_string_literal: true
# HealthReport represents a summary of checks on a given resource reporting the
# overall health of the object.
class HealthReport
  def self.for(resource)
    new(resource: resource)
  end

  # Check classes to run on each resource. Responds to #valid?, #status, #type,
  # and #summary.
  def self.check_classes
    [
      LocalFixityCheck,
      CloudFixityCheck,
      DerivativeCheck,
      VideoCaptionCheck
    ]
  end

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Symbol] Overall health status - reports the highest priority status
  #   reported by checks, as defined by #status_weights.
  def status
    all_check_statuses = checks.map(&:status).uniq
    return all_check_statuses.first if all_check_statuses.length == 1
    all_check_statuses.sort_by { |status| status_weights.fetch(status, 0) }.last
  end

  # All checks that are valid - #valid? allows for checks to only happen under
  # certain circumstances, like when a resource is ready to be preserved.
  def checks
    @checks ||=
      self.class.check_classes.map do |check_class|
        check_class.for(resource)
      end.select(&:valid?)
  end

  private

    # Assign each status a weight for sorting, if one check is needs_attention
    # and another is healthy, the overall status should be needs_attention.
    def status_weights
      {
        healthy: 0,
        in_progress: 1,
        repairing: 2,
        needs_attention: 3
      }
    end
end
