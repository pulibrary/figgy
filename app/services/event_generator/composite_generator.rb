# frozen_string_literal: true

class EventGenerator
  class CompositeGenerator
    attr_reader :generators

    def initialize(generators)
      @generators = generators
    end

    def derivatives_created(record)
      delegate_to_generator(__method__, record)
    end

    def derivatives_deleted(record)
      delegate_to_generator(__method__, record)
    end

    def record_created(record)
      delegate_to_generator(__method__, record)
    end

    def record_deleted(record)
      delegate_to_generator(__method__, record)
    end

    def record_updated(record)
      delegate_to_generator(__method__, record)
    end

    def record_member_updated(record)
      delegate_to_generator(__method__, record)
    end

    private

      # Send method with record argument to all valid generators
      def delegate_to_generator(method_name, record)
        valid_generators = generators.select { |g| g.valid?(record) }
        valid_generators.each do |generator|
          generator.send(method_name, record)
        end
      end
  end
end
