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
    :needs_attention
  end

  private

    def checks
      @checks ||=
        self.class.check_classes.map do |check_class|
          check_class.for(resource)
        end
    end
end
